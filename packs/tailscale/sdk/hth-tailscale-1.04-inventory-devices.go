// HTH Pack Contract: v1
//
//	control: tailscale-1.4
//	guide: https://howtoharden.com/guides/tailscale/#14-review-node-key-expiry-and-exceptions
//	profile: L1
//	mode: read-only
//	requires: Go 1.24+, official tailscale.com/client/tailscale/v2 v2.12.0, TAILSCALE_ACCESS_TOKEN(devices:core:read), TAILSCALE_TAILNET, TAILSCALE_OUTPUT
//
// HTH Tailscale 1.4 — Review Node Key Expiry and Exceptions; NIST IA-5, IA-3; SOC 2 CC6.2
// Source: https://github.com/tailscale/tailscale-client-go-v2/blob/main/devices.go (available; 2026-11-04)
package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"time"

	tailscale "tailscale.com/client/tailscale/v2"
)

const responseLimit = 20 * 1024 * 1024

var tokenPattern = regexp.MustCompile(`^[A-Za-z0-9._~-]+$`)
var tailnetPattern = regexp.MustCompile(`^[A-Za-z0-9-][A-Za-z0-9_.@-]{0,252}$`)

type readTransport struct {
	base    http.RoundTripper
	token   string
	tailnet string
}

// RoundTrip constrains the official SDK to one GET endpoint and checks the
// response envelope before the SDK decodes it. Missing devices is not zero devices.
func (t readTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	path := "/api/v2/tailnet/" + url.PathEscape(t.tailnet) + "/devices"
	if req.Method != http.MethodGet || req.URL.Scheme != "https" ||
		req.URL.Host != "api.tailscale.com" || req.URL.EscapedPath() != path || req.URL.RawQuery != "" {
		return nil, errors.New("unsupported request")
	}
	copy := req.Clone(req.Context())
	copy.Header.Set("Authorization", "Bearer "+t.token)
	resp, err := t.base.RoundTrip(copy)
	if err != nil {
		return nil, errors.New("transport failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, errors.New("API read failed")
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, responseLimit+1))
	if err != nil || len(body) > responseLimit {
		return nil, errors.New("incomplete or oversized response")
	}
	var envelope map[string]json.RawMessage
	if json.Unmarshal(body, &envelope) != nil || len(envelope["devices"]) == 0 || bytes.Equal(envelope["devices"], []byte("null")) {
		return nil, errors.New("invalid inventory envelope")
	}
	for _, key := range []string{"pagination", "next", "nextCursor", "nextPageToken"} {
		if _, exists := envelope[key]; exists {
			return nil, errors.New("unrecognized pagination")
		}
	}
	var devices []struct {
		ID                string  `json:"id"`
		Authorized        *bool   `json:"authorized"`
		KeyExpiryDisabled *bool   `json:"keyExpiryDisabled"`
		Expires           *string `json:"expires"`
	}
	if json.Unmarshal(envelope["devices"], &devices) != nil {
		return nil, errors.New("invalid device list")
	}
	seen := make(map[string]bool)
	for _, device := range devices {
		if device.ID == "" || seen[device.ID] || device.Authorized == nil || device.KeyExpiryDisabled == nil || device.Expires == nil {
			return nil, errors.New("missing device state or duplicate ID")
		}
		seen[device.ID] = true
	}
	resp.Body = io.NopCloser(bytes.NewReader(body))
	return resp, nil
}

// HTH Guide Excerpt: begin sdk-inventory-devices
func collectDevices(ctx context.Context, token, tailnet string, transport http.RoundTripper) ([]tailscale.Device, error) {
	client := &tailscale.Client{
		Tailnet: tailnet,
		HTTP: &http.Client{
			Timeout:       45 * time.Second,
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
			Transport:     readTransport{base: transport, token: token, tailnet: tailnet},
		},
	}
	return client.Devices().List(ctx)
}

func main() {
	if err := run(); err != nil {
		// Vendor errors can contain identity or credential data. Never print them.
		fmt.Fprintln(os.Stderr, "UNKNOWN: inventory was not saved; check inputs, credential scope and API availability")
		os.Exit(2)
	}
	fmt.Println("COLLECTED: SDK device inventory; review expiry exceptions, no compliant verdict claimed.")
}

func run() error {
	level := os.Getenv("HTH_PROFILE_LEVEL")
	if level != "" && level != "1" && level != "2" && level != "3" && level != "4" {
		return errors.New("invalid profile")
	}
	token, tailnet, output := os.Getenv("TAILSCALE_ACCESS_TOKEN"), os.Getenv("TAILSCALE_TAILNET"), os.Getenv("TAILSCALE_OUTPUT")
	if !tokenPattern.MatchString(token) || len(token) < 16 || len(token) > 4096 || !tailnetPattern.MatchString(tailnet) ||
		!filepath.IsAbs(output) || os.Getenv("TAILSCALE_BASE_URL") != "" {
		return errors.New("invalid inputs")
	}
	if _, err := os.Lstat(output); !os.IsNotExist(err) {
		return errors.New("output exists or is inaccessible")
	}
	transport := http.DefaultTransport.(*http.Transport).Clone()
	transport.TLSClientConfig = &tls.Config{MinVersion: tls.VersionTLS12}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	devices, err := collectDevices(ctx, token, tailnet, transport)
	if err != nil {
		return errors.New("inventory failed")
	}
	return saveInventory(output, devices)
}

// HTH Guide Excerpt: end sdk-inventory-devices

func saveInventory(output string, devices []tailscale.Device) error {
	// Explicit projection keeps public keys and connectivity metadata out of evidence.
	records := make([]map[string]any, 0, len(devices))
	for _, device := range devices {
		records = append(records, map[string]any{
			"id": device.ID, "nodeId": device.NodeID, "authorized": device.Authorized,
			"keyExpiryDisabled": device.KeyExpiryDisabled, "expires": device.Expires,
			"tags": device.Tags, "clientVersion": device.ClientVersion,
		})
	}
	body, err := json.MarshalIndent(map[string]any{"devices": records}, "", "  ")
	if err != nil {
		return err
	}
	file, err := os.OpenFile(output, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		return err
	}
	ok := false
	defer func() {
		file.Close()
		if !ok {
			os.Remove(output)
		}
	}()
	if _, err := file.Write(append(body, '\n')); err != nil {
		return err
	}
	if err := file.Sync(); err != nil {
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	ok = true
	return nil
}
