package main

import (
	"context"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	tailscale "tailscale.com/client/tailscale/v2"
)

type fakeTransport func(*http.Request) (*http.Response, error)

func (f fakeTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func reply(body string) *http.Response {
	return &http.Response{StatusCode: http.StatusOK, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(body))}
}

func TestSDKReadIsConstrainedAndAuthenticated(t *testing.T) {
	count := 0
	transport := fakeTransport(func(r *http.Request) (*http.Response, error) {
		count++
		if r.URL.String() != "https://api.tailscale.com/api/v2/tailnet/example.com/devices" || r.Method != "GET" {
			t.Fatal("unexpected request")
		}
		if r.Header.Get("Authorization") != "Bearer SYNTHETIC_TOKEN_ONLY" {
			t.Fatal("missing bearer authentication")
		}
		return reply(`{"devices":[{"id":"123","nodeId":"node123","authorized":true,"keyExpiryDisabled":false,"expires":"2026-12-01T00:00:00Z"}]}`), nil
	})
	devices, err := collectDevices(context.Background(), "SYNTHETIC_TOKEN_ONLY", "example.com", transport)
	if err != nil || len(devices) != 1 || count != 1 || devices[0].NodeID != "node123" {
		t.Fatalf("unexpected inventory result: count=%d length=%d error=%v", count, len(devices), err)
	}
}

func TestMissingMalformedPartialOrDuplicateInventoriesFail(t *testing.T) {
	for _, body := range []string{`{}`, `{"devices":null}`, `{"devices":{}}`, `{"devices":[{}]}`, `{"devices":[{"id":"1"}]}`,
		`{"devices":[{"id":"1","authorized":true,"keyExpiryDisabled":false,"expires":""},{"id":"1","authorized":true,"keyExpiryDisabled":false,"expires":""}]}`, `{"devices":[],"nextCursor":"more"}`, `not json`} {
		t.Run(body, func(t *testing.T) {
			transport := fakeTransport(func(*http.Request) (*http.Response, error) { return reply(body), nil })
			if _, err := collectDevices(context.Background(), "SYNTHETIC_TOKEN_ONLY", "example.com", transport); err == nil {
				t.Fatal("invalid inventory accepted")
			}
		})
	}
}

func TestRedirectAndRemoteErrorBodiesAreNotExposed(t *testing.T) {
	for _, code := range []int{302, 401, 429, 500} {
		transport := fakeTransport(func(*http.Request) (*http.Response, error) {
			r := reply("SYNTHETIC_PRIVATE_RESPONSE")
			r.StatusCode = code
			r.Header.Set("Location", "https://example.invalid/steal")
			return r, nil
		})
		_, err := collectDevices(context.Background(), "SYNTHETIC_TOKEN_ONLY", "example.com", transport)
		if err == nil || strings.Contains(err.Error(), "SYNTHETIC_PRIVATE_RESPONSE") {
			t.Fatal("remote error was accepted or exposed")
		}
	}
}

func TestNoArbitraryOriginOrWriteCanReachTransport(t *testing.T) {
	transport := readTransport{token: "SYNTHETIC_TOKEN_ONLY", tailnet: "example.com", base: fakeTransport(
		func(*http.Request) (*http.Response, error) {
			t.Fatal("unexpected transport invocation")
			return nil, errors.New("forbidden")
		})}
	for _, test := range []struct{ method, url string }{
		{"POST", "https://api.tailscale.com/api/v2/tailnet/example.com/devices"},
		{"GET", "https://example.invalid/api/v2/tailnet/example.com/devices"},
		{"GET", "http://api.tailscale.com/api/v2/tailnet/example.com/devices"},
		{"GET", "https://api.tailscale.com/api/v2/tailnet/other/devices"},
	} {
		req, _ := http.NewRequest(test.method, test.url, nil)
		if _, err := transport.RoundTrip(req); err == nil {
			t.Fatal("request escaped guard")
		}
	}
}

func TestBoundedResponses(t *testing.T) {
	transport := fakeTransport(func(*http.Request) (*http.Response, error) { return reply(strings.Repeat(" ", responseLimit+1)), nil })
	if _, err := collectDevices(context.Background(), "SYNTHETIC_TOKEN_ONLY", "example.com", transport); err == nil {
		t.Fatal("oversized response accepted")
	}
}

func TestPrivateEvidenceAndNoOverwrite(t *testing.T) {
	path := filepath.Join(t.TempDir(), "inventory.json")
	if err := saveInventory(path, []tailscale.Device{}); err != nil {
		t.Fatal(err)
	}
	info, _ := os.Stat(path)
	if info.Mode().Perm() != 0o600 {
		t.Fatal("evidence mode must be 0600")
	}
	before, _ := os.ReadFile(path)
	if err := saveInventory(path, []tailscale.Device{}); err == nil {
		t.Fatal("existing output overwritten")
	}
	after, _ := os.ReadFile(path)
	if string(before) != string(after) {
		t.Fatal("existing output changed")
	}
	link := filepath.Join(filepath.Dir(path), "symlink.json")
	if err := os.Symlink(path, link); err != nil {
		t.Fatal(err)
	}
	if err := saveInventory(link, []tailscale.Device{}); err == nil {
		t.Fatal("symlink output accepted")
	}
}

func TestInvalidInputsFailBeforeNetwork(t *testing.T) {
	t.Setenv("HTH_PROFILE_LEVEL", "0")
	if run() == nil {
		t.Fatal("invalid profile accepted")
	}
	t.Setenv("HTH_PROFILE_LEVEL", "1")
	t.Setenv("TAILSCALE_ACCESS_TOKEN", "")
	if run() == nil {
		t.Fatal("missing token accepted")
	}
	t.Setenv("TAILSCALE_TAILNET", "example.com")
	t.Setenv("TAILSCALE_OUTPUT", filepath.Join(t.TempDir(), "new.json"))
	t.Setenv("TAILSCALE_ACCESS_TOKEN", strings.Repeat("a", 4097))
	if run() == nil {
		t.Fatal("oversized token accepted")
	}
}
