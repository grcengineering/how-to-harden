---
layout: guide
title: "Windows 11 Hardening Guide"
vendor: "Microsoft"
slug: "windows-11"
tier: "3"
category: "IT Operations"
description: "Dual-track security and privacy hardening for Windows 11 — enterprise (baselines, Defender, BitLocker, Credential Guard, LAPS, ASR) and consumer (Home/Pro), with an honest, edition-scoped answer to minimizing Microsoft telemetry and connected-experience data collection."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-15"
---

**Product Editions Covered:** Windows 11 Home, Pro, Pro Education/SE, Enterprise, Education (versions 22H2–25H2)

---

## Overview

Windows 11 is two hardening problems in one box. For the **enterprise**, it is a managed endpoint governed by Group Policy, Intune, and the Microsoft security baselines, with a deep built-in defense stack — Defender Antivirus, Attack Surface Reduction, Credential Guard, BitLocker, Windows LAPS. For the **individual**, it is a consumer OS that ships permissive-by-default, wired into Microsoft accounts, connected experiences, advertising identifiers, and — on Copilot+ PCs — Recall.

This guide runs both tracks in parallel. Every control is annotated **Track: Enterprise**, **Track: Consumer**, or **Track: Both**, with the exact automation surface (PowerShell, Group Policy, Policy CSP/Intune, or registry) and its edition gating, because Windows security and privacy features are gated by edition far more than most SaaS products are.

### The honest answer to "zero Microsoft telemetry"

The goal of *totally private, zero telemetry* deserves a straight answer up front, because Microsoft's own architecture — not this guide's ambition — sets the ceiling:

- **Enterprise / Education editions can set diagnostic data to "off"** (`AllowTelemetry = 0`, the "Security" level). This is the only configuration Microsoft documents as sending *no* Windows diagnostic data, and it exists **only** on Enterprise, Education, and Server. ([Configure Windows diagnostic data](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization))
- **Home and Pro cannot reach zero.** Microsoft's Policy CSP is explicit: setting the value to `0` "on other devices is equivalent to setting the value of 1" (Required). ([Policy CSP - System](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system)) On Home/Pro the floor is **Required** diagnostic data — crash metadata and device/configuration data, collected at 100% — which you can *minimize and network-restrict* but not eliminate by supported means.
- **Some traffic never stops.** Even at Microsoft's own maximum restriction, "CRL (Certificate Revocation List) and OCSP … network traffic cannot be disabled," and Microsoft warns that disabling Windows Update, Automatic Root Certificates Update, or Defender to chase privacy *reduces* security. ([Manage connections from Windows to Microsoft services](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services))

So the realistic targets are: **Enterprise/Education → policy-enforced zero diagnostic data plus the restricted-traffic baseline**; **Home/Pro → Required-floor plus every consumer privacy toggle and network restriction**, with the residual (Required diagnostics, revocation checks, activation) stated rather than hidden. Section 5 delivers both, per edition, without overpromising.

### Intended Audience

- Enterprise security engineers and IT administrators deploying Windows 11 at scale
- Privacy-conscious individuals hardening a personal Home/Pro device
- GRC professionals mapping Windows 11 posture to CIS, DISA STIG, and NIST
- Incident responders establishing an endpoint monitoring baseline

### How to Use This Guide

- **L1 (Crawl):** Essential controls for every device
- **L2 (Walk):** Enhanced controls for security- or privacy-sensitive environments
- **L3 (Run):** Strictest controls for regulated or high-threat environments
- **L4 (Fly):** Maximum-assurance controls (rare; most devices need only L1–L3)

Each control also carries a **Track** line naming who it applies to and how far each edition can go.

### Scope

Covers Windows 11 client hardening: identity and credential protection, OS/boot integrity, the Defender attack-surface stack, data-at-rest encryption, privacy and telemetry reduction, network and update hardening, and endpoint monitoring — across consumer (Home/Pro) and enterprise (Pro/Enterprise/Education) editions. Does not cover Windows Server, Windows 10, third-party AV/EDR products, or activation topics. Community "debloat"/privacy scripts are deliberately excluded — every setting here traces to Microsoft's own documentation.

---

## Table of Contents

1. [Identity & Credential Protection](#1-identity--credential-protection)
2. [OS & Boot Integrity](#2-os--boot-integrity)
3. [Attack Surface Reduction](#3-attack-surface-reduction)
4. [Data Protection](#4-data-protection)
5. [Privacy & Telemetry](#5-privacy--telemetry)
6. [Network & Update Hardening](#6-network--update-hardening)
7. [Monitoring & Detection](#7-monitoring--detection)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

**Controls at a glance**

| # | Control | Level | Track |
|---|---------|-------|-------|
| [1.1](#11-apply-a-microsoft-security-baseline-enterprise-or-harden-accounts-consumer) | Baseline / account foundation | L1 | Both |
| [1.2](#12-protect-sign-in-credentials-windows-hello-credential-guard-lsa-protection) | Credential protection (Hello, Credential Guard, LSA) | L1 | Both |
| [1.3](#13-rotate-local-administrator-passwords-with-windows-laps) | Windows LAPS | L2 | Enterprise |
| [2.1](#21-verify-secure-boot-and-tpm-20) | Secure Boot + TPM 2.0 | L1 | Both |
| [2.2](#22-enable-memory-integrity-vbshvci) | Memory integrity (VBS/HVCI) | L1 | Both |
| [2.3](#23-enable-smart-app-control-consumer) | Smart App Control | L2 | Consumer |
| [3.1](#31-harden-microsoft-defender-antivirus) | Defender Antivirus + tamper protection | L1 | Both |
| [3.2](#32-enable-attack-surface-reduction-asr-rules) | ASR rules | L2 | Both |
| [3.3](#33-enable-controlled-folder-access-and-network-protection) | Controlled folder access + network protection | L2 | Both |
| [4.1](#41-encrypt-the-system-drive-bitlocker-or-device-encryption) | BitLocker / Device Encryption | L1 | Both |
| [4.2](#42-govern-the-encryption-recovery-key) | Recovery-key governance | L1 | Both |
| [5.1](#51-set-diagnostic-data-to-the-lowest-your-edition-allows) | Diagnostic data floor | L1 | Both |
| [5.2](#52-apply-the-restricted-traffic-and-connected-experiences-baseline) | Restricted-traffic / connected experiences | L2 | Both |
| [5.3](#53-disable-advertising-tailored-experiences-and-activity-collection) | Advertising / tailored experiences / activity | L1 | Both |
| [5.4](#54-govern-recall-and-copilot) | Recall & Copilot | L2 | Both |
| [6.1](#61-harden-the-windows-firewall) | Windows Firewall | L1 | Both |
| [6.2](#62-harden-smb-and-block-legacy-ntlm) | SMB signing + NTLM | L2 | Both |
| [6.3](#63-control-delivery-optimization-and-update-currency) | Delivery Optimization + updates | L2 | Both |
| [7.1](#71-establish-endpoint-audit-logging-and-detection) | Audit logging & detection | L2 | Both |

---

## 1. Identity & Credential Protection

### 1.1 Apply a Microsoft Security Baseline (Enterprise) or Harden Accounts (Consumer)

**Profile Level:** L1 (Crawl)

**Track:** Both — the mechanism differs sharply by edition.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 4.7 |
| NIST 800-53 | CM-2, CM-6 |

#### Description
Start from a known-good configuration rather than the shipped defaults. On **Enterprise/Pro/Education**, apply a Microsoft security baseline from the Security Compliance Toolkit (or the Intune Security Baseline for Windows). On **Home**, where Group Policy tooling and the baselines are not supported, the equivalent foundation is account hygiene: prefer a standard (non-administrator) daily account and understand the Microsoft-account defaults.

#### Rationale
**Why This Matters:**

- Windows 10 alone exposes "over 3,000 group policy settings," and Microsoft's own guidance is to adopt "an industry-standard, well-tested" baseline rather than authoring one from scratch — the baseline encodes Microsoft's security engineering judgment
- The baselines are "designed for well-managed, security-conscious organizations in which standard end users don't have administrative rights" — the same non-admin-daily-user principle is the single highest-value consumer control
- Home is **absent** from Microsoft's baseline edition-support table (which lists only Pro, Enterprise, Pro Education/SE, and Education) — a Home user should know the baseline path is unavailable and not chase community scripts that impersonate it

**Attack Prevented:** Configuration drift, exploitation of insecure defaults, malware leveraging standing administrator rights

#### Prerequisites
- Enterprise: Pro or higher; Group Policy (GPMC/`gpedit.msc`) or Intune; the [Security Compliance Toolkit](https://www.microsoft.com/download/details.aspx?id=55319)
- Consumer: administrator access to create a separate standard account

#### ClickOps Implementation

**Enterprise — apply the baseline (GPO path):**
1. Download the Security Compliance Toolkit and extract the Windows 11 baseline (versions 21H2–25H2 are provided; the current package targets **25H2**)
2. For domain-wide deployment, import the provided GPO backups via the Group Policy Management Console
3. For a standalone machine, use **LGPO.exe** (included in the SCT) to import the baseline's `Registry.pol`, security template, and auditing backups into Local Group Policy
4. Use **Policy Analyzer** (with **GPO2PolicyRules**) to compare the applied state against the baseline and detect drift

**Enterprise — Intune alternative:**
1. In the Intune admin center, go to **Endpoint security → Security baselines → Security Baseline for Windows 10 and later** (current version **25H2**) and create a profile. Microsoft notes the Intune baseline matches the GPO baseline minus domain-controller-only settings.

**Consumer — account foundation (Home/Pro):**
1. Create a separate standard-user account for daily use: **Settings → Accounts → Other users → Add account**, and when prompted choose **"I don't have this person's sign-in information" → "Add a user without a Microsoft account"** (URI `ms-settings:otherusers`)
2. Reserve the administrator account for installs and configuration only

**Time to Complete:** Enterprise ~2–4 hours; Consumer ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="1.1" %}

#### Validation & Testing
1. Enterprise: run Policy Analyzer against the baseline `.PolicyRules` and confirm no unexpected deltas
2. Consumer: confirm daily sign-in is a standard account (UAC prompts for admin credentials rather than a yes/no consent)

**Expected result:** The device matches a Microsoft-recommended baseline (Enterprise) or runs day-to-day as a non-administrator (Consumer).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Windows 11** | Benchmark v5.1.0 (Enterprise) / v5.0.0 (Stand-alone) | Baseline configuration — map by name; verify recommendation numbers against the current benchmark PDF |
| **NIST 800-53** | CM-2, CM-6 | Baseline configuration; configuration settings |
| **ISO 27001:2022** | 8.9 | Configuration management |

---

### 1.2 Protect Sign-in Credentials: Windows Hello, Credential Guard, LSA Protection

**Profile Level:** L1 (Crawl)

**Track:** Both — with a hard enterprise-only line at Credential Guard.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.2, 6.3 |
| NIST 800-53 | IA-2, IA-5 |

#### Description
Replace password-only sign-in with Windows Hello (biometric/PIN, on-device), and — where the edition allows — isolate derived credentials in virtualization-based security so credential-theft tools cannot read them. **Credential Guard** protects domain/cloud secrets and is **Enterprise/Education only**. **LSA protection** (RunAsPPL) hardens the LSASS process against tampering and is available broadly. Both are default-on for qualifying installs since 22H2.

#### Rationale
**Why This Matters:**

- Windows Hello biometric data "is stored … securely on the local device only … never sent to external devices or servers" — a privacy-positive authentication upgrade as well as a phishing-resistance one
- Credential Guard, when enabled, blocks Kerberos DES, unconstrained delegation, TGT extraction, and NTLMv1 — the exact primitives credential-theft and lateral-movement toolkits rely on — and is enabled by default on domain-joined non-DC Enterprise/Education systems since 22H2
- LSA protection (RunAsPPL) is enabled by default on new 22H2+ installs and stops non-protected processes from reading LSASS memory

**Attack Prevented:** Credential theft (LSASS dumping, pass-the-hash, pass-the-ticket), phishing of reusable passwords

#### Prerequisites
- Windows Hello: a compatible camera/fingerprint reader or a PIN
- Credential Guard: **Enterprise or Education**, VBS + Secure Boot (see 2.2); TPM recommended
- LSA protection: UEFI + Secure Boot recommended for the UEFI-lock variant

#### ClickOps Implementation

**Consumer — Windows Hello:**
1. **Settings → Accounts → Sign-in options** → set up **Facial recognition**, **Fingerprint**, or **PIN**

**Enterprise — verify/enable Credential Guard (Enterprise/Education):**
1. It is default-on for qualifying domain-joined devices; to enforce, use **Computer Configuration → Administrative Templates → System → Device Guard → "Turn On Virtualization Based Security"** → Enabled, with **Credential Guard Configuration = "Enabled with UEFI lock"**
2. Verify with the `Win32_DeviceGuard` WMI class (see the pack)

**Both — confirm LSA protection:**
1. Registry `HKLM\SYSTEM\CurrentControlSet\Control\Lsa` value `RunAsPPL` = `1` (UEFI variable) or `2` (without UEFI variable, 22H2+); or Local GPO **System → Local Security Authority → "Configures LSASS to run as a protected process"**

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="1.2" %}

#### Validation & Testing
1. `Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard` → `SecurityServicesRunning` contains `1` (Credential Guard running) on Enterprise/Education
2. Confirm `RunAsPPL` is set; confirm Windows Hello is enrolled for the daily user

**Expected result:** Sign-in uses Hello; LSASS runs protected; Credential Guard runs where the edition supports it.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **CIS Windows 11** | v5.x (map by name) | Credential/LSA protection |
| **NIST 800-53** | IA-2, IA-5, SC-39 | Authentication; process isolation |
| **ISO 27001:2022** | 5.16, 5.17 | Identity and authentication information |

---

### 1.3 Rotate Local Administrator Passwords with Windows LAPS

**Profile Level:** L2 (Walk)

**Track:** Enterprise — requires AD or Microsoft Entra join (not available on Home).

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 5.2, 5.4 |
| NIST 800-53 | IA-5, AC-6 |

#### Description
Windows LAPS is the built-in, no-cost feature that automatically rotates and escrows the local administrator password to Microsoft Entra ID **or** Active Directory (never both), removing shared/static local-admin passwords across the fleet.

#### Rationale
**Why This Matters:**

- A single reused local-admin password across a fleet is a lateral-movement highway; LAPS makes each device's local-admin credential unique and rotated
- It is built into Windows 11 (23H2 and later, plus patched earlier builds) at no license cost, so there is no procurement excuse to run without it
- Escrow to Entra/AD keeps recovery possible without a spreadsheet of passwords

**Attack Prevented:** Lateral movement via shared local-administrator credentials, pass-the-hash across identical local accounts

#### Prerequisites
- Devices joined to Microsoft Entra ID or Active Directory
- LAPS policy delivered via GPO (**Computer Configuration → Policies → Administrative Templates → System → LAPS**) or the LAPS CSP (Intune)

#### ClickOps Implementation

1. Set the master switch `BackupDirectory`: `1` = back up to Microsoft Entra, `2` = back up to Active Directory (`0` = disabled)
2. For AD, extend the schema (`Update-LapsADSchema`) and grant the device self-permission
3. Configure password length/complexity and rotation age via the LAPS policy
4. Retrieve or force-rotate with the LAPS PowerShell module

**Time to Complete:** ~1 hour initial setup

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="1.3" %}

#### Validation & Testing
1. `Get-LapsADPassword` / `Get-LapsAADPassword` returns a current, rotated password
2. `Reset-LapsPassword` forces an immediate rotation and the new value escrows successfully

**Expected result:** Every managed device has a unique, rotated, escrowed local-administrator password.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | IA-5, AC-6 | Authenticator management; least privilege |
| **CIS Windows 11** | v5.x (map by name) | Local administrator password management |
| **ISO 27001:2022** | 5.17 | Authentication information |

---

## 2. OS & Boot Integrity

### 2.1 Verify Secure Boot and TPM 2.0

**Profile Level:** L1 (Crawl)

**Track:** Both.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1 |
| NIST 800-53 | SI-7, SC-51 |

#### Description
Confirm the platform's hardware root of trust is active: UEFI **Secure Boot** enabled and **TPM 2.0** present and owned. Both are Windows 11 hardware requirements; Windows automatically initializes and takes ownership of the TPM, so the task is verification, not reconfiguration.

#### Rationale
**Why This Matters:**

- Secure Boot blocks unsigned bootloaders and boot-time rootkits; several 2024–2025 attacks (see the BitLocker `bitpixie` VMK-extraction research, CVE-2023-21563) turn specifically on downgrading or subverting the boot path
- Windows "automatically initializes and takes ownership of the TPM," and Microsoft recommends **avoiding** manual configuration via `TPM.msc` — verify state instead of touching it
- TPM 2.0 underpins Credential Guard, BitLocker, and Device Health Attestation; a device with legacy BIOS "won't work as expected"

**Attack Prevented:** Bootkits, boot-path downgrade attacks, tampering with pre-OS integrity

#### ClickOps Implementation
1. **Settings → Privacy & security → Windows Security → Device security** shows **Secure boot** and **Security processor (TPM)** status
2. Or run `msinfo32.exe` and read **Secure Boot State** and **TPM** under System Summary

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="2.1" %}

#### Validation & Testing
1. `Confirm-SecureBootUEFI` returns `$True` (run as administrator)
2. `Get-Tpm` (or `msinfo32`) shows TPM present, ready, and version 2.0

**Expected result:** Secure Boot on, TPM 2.0 present and owned.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-7, SC-51 | Software/firmware integrity; hardware root of trust |
| **CIS Windows 11** | v5.x (map by name) | Secure Boot / TPM |
| **ISO 27001:2022** | 8.9 | Configuration management |

---

### 2.2 Enable Memory Integrity (VBS/HVCI)

**Profile Level:** L1 (Crawl)

**Track:** Both — consumer via a Windows Security toggle, enterprise via policy.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 10.5 |
| NIST 800-53 | SI-7, SC-39 |

#### Description
Turn on **Memory integrity** (Hypervisor-protected Code Integrity, HVCI), which runs on Virtualization-Based Security to verify kernel-mode drivers and code in an isolated environment — blocking a large class of kernel exploits and vulnerable/malicious drivers.

#### Rationale
**Why This Matters:**

- HVCI moves code-integrity enforcement into a VBS-isolated context the kernel itself cannot tamper with, defeating driver-based (BYOVD) and kernel-memory attacks
- Since 22H2, Windows Security actively warns when memory integrity is off — Microsoft treats "off" as a degraded state
- It is the substrate Credential Guard also depends on, so enabling it advances 1.2 as well

**Attack Prevented:** Kernel-mode code injection, exploitation of vulnerable signed drivers (BYOVD)

#### Prerequisites
- VBS-capable hardware (Secure Boot; compatible drivers). Incompatible drivers must be updated first.

#### ClickOps Implementation

**Consumer:**
1. **Windows Security → Device security → Core isolation details → Memory integrity** → On (reboot required)

**Enterprise (GPO):**
1. **Computer Configuration → Administrative Templates → System → Device Guard → "Turn on Virtualization Based Security"** → Enabled; under **Virtualization Based Protection of Code Integrity** select **"Enabled without UEFI lock"** (or with lock for stricter deployments)

**Time to Complete:** ~15 minutes plus reboot

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="2.2" %}

#### Validation & Testing
1. `Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard` → `VirtualizationBasedSecurityStatus = 2` and `SecurityServicesRunning` contains `2` (memory integrity running)
2. Or read the VBS section at the bottom of `msinfo32` System Summary

**Expected result:** VBS enabled and running; memory integrity active.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-7, SC-39 | Code integrity; process isolation |
| **CIS Windows 11** | v5.x (map by name) | Device Guard / VBS |
| **ISO 27001:2022** | 8.7 | Protection against malware |

---

### 2.3 Enable Smart App Control (Consumer)

**Profile Level:** L2 (Walk)

**Track:** Consumer — clean-install-only; enterprises use WDAC/AppLocker instead.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 2.5, 2.6 |
| NIST 800-53 | CM-7, SI-3 |

#### Description
Smart App Control blocks malware, potentially unwanted apps, and unsigned/untrusted code by default, using Microsoft's cloud reputation and code-signing signals. It "can only be enabled on a clean install" (a device reset counts) because it is designed to protect a device for its whole lifetime.

#### Rationale
**Why This Matters:**

- It is a default-deny execution control for consumers who otherwise have no application allowlisting — malware, PUA, and unknown unsigned code are blocked outright
- Because it cannot be turned on after the fact on a used install, it is a decision to make at setup/reset time — worth knowing before a clean install rather than after
- Enterprises should not rely on it (it is a consumer feature); App Control for Business (WDAC)/AppLocker are the managed equivalents

**Attack Prevented:** Execution of untrusted/unsigned malware and potentially unwanted applications

#### Prerequisites
- Windows 11 version 22572 or higher, on a **clean install or reset**

#### ClickOps Implementation
1. Check state at **Settings → Windows Security → App and Browser control → Smart App Control** — **On** (enforcement), **Evaluation** (learning), or **Off**
2. If Off on a used install, it can only be turned on by performing a clean install/reset

**Time to Complete:** ~5 minutes to verify (or a reset to enable)

#### Validation & Testing
1. Confirm the state shows **On** (enforcement mode) after evaluation
2. Attempt to run an unsigned unknown binary — it should be blocked

**Expected result:** Untrusted code is blocked at execution on the consumer device.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | CM-7, SI-3 | Least functionality; malicious code protection |
| **ISO 27001:2022** | 8.19 | Installation of software on operational systems |

---

## 3. Attack Surface Reduction

### 3.1 Harden Microsoft Defender Antivirus

**Profile Level:** L1 (Crawl)

**Track:** Both — the same `Set-MpPreference` cmdlets work on Home.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 10.1, 10.6 |
| NIST 800-53 | SI-3, SI-4 |

#### Description
Turn on cloud-delivered protection, potentially-unwanted-app blocking, and — critically — **tamper protection**, which locks Defender's own settings against modification by malware or misconfiguration. All are available on Home; tamper protection is set through the Windows Security app on unmanaged devices.

#### Rationale
**Why This Matters:**

- Cloud-delivered protection (MAPS) plus sample submission enables Block-at-First-Sight; disabling sample submission (`NeverSend`) lowers the protection state and turns Block-at-First-Sight off
- Tamper protection defends the AV against exactly the disable-the-defender step in modern intrusions — and the 2025 **EDR-Freeze** research showed user-mode techniques that suspend Defender via Windows Error Reporting, making settings-integrity a live concern
- PUA protection blocks adware, bundleware, and low-reputation software before it runs

**Attack Prevented:** Malware execution, defender-disable/tampering, potentially unwanted application installs

#### ClickOps Implementation

**Consumer/unmanaged — tamper protection:**
1. **Windows Security → Virus & threat protection → Manage settings → Tamper Protection** → On

**Enterprise (GPO):**
1. **Computer configuration → Administrative templates → Windows components → Microsoft Defender Antivirus → MAPS** → "Join Microsoft MAPS = Advanced MAPS" and "Send file samples when further analysis is required = Send safe samples"
2. Tamper protection is managed via Intune/Defender for Endpoint for managed fleets

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="3.1" %}

#### Validation & Testing
1. `Get-MpComputerStatus` → `IsTamperProtected` and `RealTimeProtectionEnabled` are `True`
2. `Get-MpPreference | Format-Table MAPSReporting, SubmitSamplesConsent, PUAProtection` shows Advanced / SendSafeSamples / Enabled (1)

**Expected result:** Defender runs with cloud protection, PUA blocking, and tamper protection locked on.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3, SI-4 | Malicious code protection; monitoring |
| **CIS Windows 11** | v5.x (map by name) | Microsoft Defender configuration |
| **ISO 27001:2022** | 8.7 | Protection against malware |

---

### 3.2 Enable Attack Surface Reduction (ASR) Rules

**Profile Level:** L2 (Walk)

**Track:** Both — ASR rules run on any edition with Defender AV, including Home, configured locally via PowerShell.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 10.5, 9.4 |
| NIST 800-53 | SI-3, CM-7 |

#### Description
Enable ASR rules — targeted behavioral blocks against common malware and exploit techniques (Office spawning child processes, credential theft from LSASS, executable content from email, script-launched executables, and more). Each rule is a GUID set to Disabled (0), Block (1), Audit (2), Not Configured (5), or Warn (6). Microsoft's guidance is to Block the three "standard protection" rules broadly and Audit the rest first.

#### Rationale
**Why This Matters:**

- ASR converts whole classes of intrusion technique into blocked events — for example, "Block credential stealing from the Windows local security authority subsystem" (`9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2`) directly counters LSASS-dumping toolkits
- The three standard-protection rules (vulnerable-driver abuse, LSASS credential theft, WMI-persistence) are "recommended to enable … without extensive testing"
- ASR requires Defender AV in active mode with real-time and cloud protection on — it composes with 3.1 rather than replacing it

**Attack Prevented:** Living-off-the-land execution, credential theft, macro/script-borne malware, WMI persistence

#### Prerequisites
- Defender AV active mode; real-time and cloud-delivered protection on; recent platform/engine

#### ClickOps Implementation

**Enterprise (GPO):**
1. **Computer configuration → Administrative templates → Windows components → Microsoft Defender Antivirus → Microsoft Defender Exploit Guard → Attack Surface Reduction → "Configure Attack Surface Reduction rules"** → Enabled, then add each rule GUID with its state (1=Block, 2=Audit)

**Both — PowerShell (works on Home):** see the pack; start standard rules in Block, others in Audit, then promote.

**Time to Complete:** ~30 minutes plus audit-review cycle

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="3.2" %}

#### Validation & Testing
1. `Get-MpPreference | Select-Object AttackSurfaceReductionRules_Ids, AttackSurfaceReductionRules_Actions` reflects the intended GUID/state pairs
2. Review Audit-mode events before promoting a rule to Block; confirm no legitimate workflow breaks

**Expected result:** Standard-protection ASR rules in Block; remaining rules in Audit pending review.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3, CM-7 | Malicious code protection; least functionality |
| **CIS Windows 11** | v5.x (map by name) | Attack Surface Reduction rules |
| **ISO 27001:2022** | 8.7 | Protection against malware |

---

### 3.3 Enable Controlled Folder Access and Network Protection

**Profile Level:** L2 (Walk)

**Track:** Both — both are consumer-usable via the Windows Security app or PowerShell.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 10.1, 13.3 |
| NIST 800-53 | SI-3, SC-7 |

#### Description
Turn on **Controlled folder access** (ransomware protection for user folders — only allowed apps may modify protected folders) and **Network protection** (blocks connections to low-reputation/malicious domains for all apps, not just the browser).

#### Rationale
**Why This Matters:**

- Controlled folder access is a direct ransomware mitigation: unauthorized processes cannot encrypt Documents/Pictures/etc.
- Network protection extends SmartScreen-style URL reputation to *every* process, catching malware C2 and phishing that bypasses the browser
- Both are free, built in, and available to consumers — Network protection requires `Enabled` **plus** Block mode (Enabled alone is insufficient)

**Attack Prevented:** Ransomware file encryption, malware command-and-control, phishing/drive-by across non-browser apps

#### ClickOps Implementation

**Consumer:**
1. Controlled folder access: **Windows Security → Virus & threat protection → Ransomware protection → Manage ransomware protection → Controlled folder access** → On
2. Network protection has no consumer toggle — set it via PowerShell (see the pack)

**Enterprise (GPO):**
1. Network protection: **… Microsoft Defender Exploit Guard → Network protection → "Prevent users and apps from accessing dangerous websites"** → Enabled + **Block**

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="3.3" %}

#### Validation & Testing
1. `Get-MpPreference | Format-Table EnableControlledFolderAccess, EnableNetworkProtection` shows Enabled (1)
2. Test controlled folder access by having a non-allowlisted app attempt to write to a protected folder — it should be blocked

**Expected result:** User folders are protected from unauthorized modification; dangerous domains are blocked system-wide.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-3, SC-7 | Malicious code protection; boundary protection |
| **CIS Windows 11** | v5.x (map by name) | Exploit Guard protections |
| **ISO 27001:2022** | 8.7 | Protection against malware |

---

## 4. Data Protection

### 4.1 Encrypt the System Drive (BitLocker or Device Encryption)

**Profile Level:** L1 (Crawl)

**Track:** Both — full BitLocker on Pro+, Device Encryption on Home.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.6, 3.11 |
| NIST 800-53 | SC-28 |

#### Description
Encrypt the operating-system drive at rest. **Pro/Enterprise/Education** get full **BitLocker** (policy, cipher choice, PIN/TPM protectors). **Home** gets **Device Encryption**, which — since Windows 11 24H2 — no longer requires Modern Standby/HSTI hardware and covers far more devices; it uses XTS-AES 128-bit by default and encrypts the OS and fixed drives (not USB/external).

#### Rationale
**Why This Matters:**

- Full-disk encryption is the baseline defense for a lost or stolen device — without it, drive removal reads all data in the clear
- On 24H2, Device Encryption may auto-enable after setup; understanding that (and where the recovery key goes — see 4.2) is essential on Home
- Encryption is not a boot-integrity substitute: the `bitpixie` research (38C3, CVE-2023-21563) extracts the BitLocker Volume Master Key via a downgraded boot manager without opening the case — mitigated substantially by a **TPM+PIN** protector, which Home's automatic Device Encryption does not offer

**Attack Prevented:** Data theft from lost/stolen devices, offline drive-removal attacks

#### Prerequisites
- A device meeting encryption prerequisites (`msinfo32` → **Device Encryption Support**); TPM present

#### ClickOps Implementation

**Consumer (Home) — Device Encryption:**
1. **Settings → Privacy & security → Device encryption** → On (if the toggle is present)

**Enterprise/Pro — BitLocker:**
1. **Control Panel → BitLocker Drive Encryption → Turn on BitLocker**, choosing a protector (TPM, or **TPM+PIN** for L2/L3), and back up the recovery key per 4.2
2. For L2/L3, prefer **TPM+PIN** and **XTS-AES 256**

**Time to Complete:** ~30 minutes plus encryption time

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="4.1" %}

#### Validation & Testing
1. `Get-BitLockerVolume C:` shows `ProtectionStatus = On` and `VolumeStatus = FullyEncrypted` (Control Panel "Waiting for Activation" means a clear key still exists — resolve per 4.2)
2. Confirm the encryption method (`XtsAes256` for hardened deployments)

**Expected result:** The system drive is fully encrypted and fully protected (no clear key).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **CIS Windows 11** | v5.x BitLocker (BL) profile | Drive encryption |
| **ISO 27001:2022** | 8.24 | Use of cryptography |

---

### 4.2 Govern the Encryption Recovery Key

**Profile Level:** L1 (Crawl)

**Track:** Both — and the consumer privacy tension lives here.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Control where the recovery key is escrowed. **Enterprise:** back it up to Active Directory or Microsoft Entra via the "Choose how BitLocker-protected operating system drives can be recovered" policy (and require escrow before encryption for silent deployments). **Consumer:** understand that Home Device Encryption **escrows the recovery key to your Microsoft account by default** — the privacy-vs-recoverability decision — and know the alternatives.

#### Rationale
**Why This Matters:**

- The recovery key is the master override for the whole drive — its custody is the actual security boundary, not the encryption itself
- On Home, the default is escrow to the Microsoft account: convenient and recoverable, but it places the key with Microsoft. Microsoft is explicit that a **local-account-only** device "remains unprotected even though the data is encrypted" (the clear key is never removed without an escrow target), so the honest tradeoff is *Microsoft-account escrow* vs *manual key custody* vs *no protection*
- The privacy-maximizing consumer path is manual custody: back the key up to a USB/file/print and store it offline, or prevent auto-encryption entirely (`PreventDeviceEncryption`) if you will manage BitLocker yourself on Pro

**Attack Prevented:** Permanent data loss (no recovery key), and — on the privacy side — unnecessary escrow of the drive's master key to a third party

#### ClickOps Implementation

**Enterprise (GPO):**
1. **Computer Configuration → Administrative Templates → Windows Components → BitLocker Drive Encryption → Operating System Drives → "Choose how BitLocker-protected operating system drives can be recovered"** → Enabled, select **"Save BitLocker recovery information to Active Directory Domain Services"** (or use the Entra/Intune escrow path), and optionally **"Do not enable BitLocker until recovery information is stored in AD DS"**

**Consumer — take manual custody of the key:**
1. Start → search **BitLocker → Manage BitLocker → Back up your recovery key**, and choose **Save to a USB flash drive**, **Save to a file**, or **Print** — store it offline
2. To avoid Microsoft-account escrow entirely and manage encryption yourself (Pro): set registry `HKLM\SYSTEM\CurrentControlSet\Control\BitLocker` value `PreventDeviceEncryption` = `1` before enabling BitLocker manually

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="4.2" %}

#### Validation & Testing
1. Enterprise: confirm the recovery key appears in AD DS / Entra for the device and the volume shows fully protected
2. Consumer: confirm you hold an offline copy of the recovery key and can produce it; decide and document the escrow posture

**Expected result:** The recovery key is escrowed to the intended custodian (enterprise directory, or the user's own offline storage) — never left implicit.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-12, SC-28 | Cryptographic key management; protection at rest |
| **CIS Windows 11** | v5.x BitLocker (BL) profile | Recovery key escrow |
| **ISO 27001:2022** | 8.24 | Use of cryptography |

---

## 5. Privacy & Telemetry

> This section carries the guide's honest, edition-scoped answer to *"zero Microsoft telemetry."* Read the [Overview](#the-honest-answer-to-zero-microsoft-telemetry) first: Enterprise/Education can reach policy-enforced zero diagnostic data; Home/Pro cannot, and the floor plus residual is stated here rather than wished away.

### 5.1 Set Diagnostic Data to the Lowest Your Edition Allows

**Profile Level:** L1 (Crawl)

**Track:** Both — with a hard edition floor.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.1, 3.3 |
| NIST 800-53 | SI-12, PL-4 |

#### Description
Set Windows diagnostic data to the minimum your edition supports. The three current levels are **Diagnostic data off** (`0`, "Security"), **Required** (`1`, "Basic"), and **Optional** (`3`, "Full"); Enhanced (`2`) is retired on Windows 11. **Only Enterprise, Education, and Server honor `0`** — on Pro and Home, `0` is silently treated as `1` (Required).

#### Rationale
**Why This Matters:**

- On Enterprise/Education this is the single control that achieves *no Windows diagnostic data* — the literal "zero telemetry" state, enforceable by policy
- On Home/Pro, the honest ceiling is **Required**: crash metadata plus device/configuration data at 100% collection. Optional (Full) adds typed/inked content sampling, browsing, and richer usage — moving from Optional to Required is the biggest single privacy gain available to a consumer
- Microsoft's caveat is worth heeding: if you rely on Windows Update, "off" collects no update-failure data, so Required is Microsoft's recommended minimum for update-dependent fleets — a deliberate tradeoff, not an oversight

**Attack Prevented (privacy):** Excess telemetry egress; over-collection of user content and usage under Optional diagnostics

#### Prerequisites
- Enterprise/Education for the `0` (off) level; any edition for Required
- The Diagnostic Data Viewer to inspect what actually leaves the device

#### ClickOps Implementation

**Consumer (Home/Pro) — reduce to Required:**
1. **Settings → Privacy & security → Diagnostics & feedback** → turn **Send optional diagnostic data** **Off** (this leaves the Required floor)
2. Also turn off **Improve inking and typing** on the same page, and use **Delete diagnostic data** (note: this does not delete data tied to your Microsoft account)

**Enterprise/Education — set to off (GPO):**
1. **Computer Configuration → Administrative Templates → Windows Components → Data Collection and Preview Builds → "Allow Diagnostic Data"** → Enabled → **"Diagnostic data off"** (registry `HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection` value `AllowTelemetry` = `0`)
2. Optionally lock the Settings UI so users cannot raise it (**"Configure diagnostic data opt-in settings user interface"** = Disable Telemetry opt-in Settings)

**Time to Complete:** ~10 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="5.1" %}

#### Validation & Testing
1. Use the **Diagnostic Data Viewer** (`Settings → Privacy & security → Diagnostics & feedback → View diagnostic data`, or the `Get-DiagnosticData` PowerShell module) to observe exactly what the device is sending
2. Enterprise/Education: confirm `AllowTelemetry = 0` in the policy registry key. Note the Security/off level "will not be reflected in the UI" when set by policy — verify via the registry, not the Settings toggle
3. Home/Pro: confirm optional diagnostics are Off; accept that Required is the floor and cannot read `0`

**Expected result:** Enterprise/Education send no Windows diagnostic data; Home/Pro send only the Required floor, inspected and confirmed via the Diagnostic Data Viewer.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-12, PL-4 | Information handling and retention; rules of behavior |
| **CIS Windows 11** | v5.x (map by name) | Allow Diagnostic Data |
| **ISO 27001:2022** | 5.34 | Privacy and protection of PII |

---

### 5.2 Apply the Restricted-Traffic and Connected-Experiences Baseline

**Profile Level:** L2 (Walk)

**Track:** Both — the policies are Enterprise/Server-scoped, but many registry equivalents are honored on Pro (verify per setting); Home relies on Settings toggles.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.8, 3.3 |
| NIST 800-53 | SC-7, SI-12 |

#### Description
Disable the connected experiences that reach out to Microsoft services — web-connected search/Cortana, Find My Device, OneDrive pre-sign-in traffic, Windows Spotlight, settings sync, the activity feed, and the news/Widgets feed — using Microsoft's own **"Manage connections from Windows … to Microsoft services"** guidance (the Restricted Traffic Limited Functionality Baseline). Apply it deliberately, because **some restrictions reduce security**.

#### Rationale
**Why This Matters:**

- This is Microsoft's documented, supported set of controls for minimizing outbound connections — far safer than community "debloat" scripts, which are not cited here on principle
- Microsoft's own warning is the guardrail: disabling **Windows Update, Automatic Root Certificates Update, or Microsoft Defender** to chase privacy makes the device *less* secure — do not disable those, and note that CRL/OCSP revocation traffic "cannot be disabled" regardless
- **SmartScreen** is a specific privacy-vs-security fork: disabling it removes URL/app reputation checks (a real anti-phishing/anti-malware control). This guide's recommendation is to **keep SmartScreen on** and accept its reputation lookups as a security necessity, rather than disable it for marginal privacy

**Attack Prevented (privacy):** Connected-experience data collection, cloud sync of settings/activity, feed/Spotlight content requests

#### Prerequisites
- Enterprise/Server for the full policy baseline; Pro honors many `Policies` registry keys (verify per setting); Home uses Settings toggles

#### ClickOps Implementation

**Enterprise — representative policies (all under Computer/User Configuration → Administrative Templates):**
1. Web search: **Windows Components → Search** → "Allow Cortana" = Disabled, "Do not allow web search" = Enabled, "Don't search the web or display web results in Search" = Enabled
2. Find My Device: **Windows Components → Find My Device** → "Turn On/Off Find My Device" = Disabled
3. OneDrive: **Windows Components → OneDrive** → "Prevent the usage of OneDrive for file storage" = Enabled
4. Settings sync: **Windows Components → Sync your settings** → "Do not sync" = Enabled
5. Activity feed: **System → OS Policies** → "Enables Activity Feed", "Allow publishing of User Activities", "Allow upload of User Activities" = Disabled
6. **Do not** disable Windows Update, Root Certificate updates, or Defender

**Consumer — Settings-app equivalents:**
1. Turn off OneDrive sync, disable Widgets (**Taskbar settings → Widgets** Off), and set Spotlight/lock-screen tips off in **Personalization**

**Time to Complete:** Enterprise ~1–2 hours; Consumer ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="5.2" %}

#### Validation & Testing
1. Confirm the intended registry values are set (e.g., `HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search` → `DisableWebSearch = 1`)
2. Capture a network trace and confirm connected-experience endpoints are quiet — while accepting that revocation (CRL/OCSP), activation, and Required diagnostics traffic remain
3. Confirm SmartScreen is still **on** (security decision) unless your threat model explicitly overrides it

**Expected result:** Connected experiences are disabled to the extent the edition supports, security-critical services remain on, and residual traffic is understood.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-7, SI-12 | Boundary protection; information handling |
| **CIS Windows 11** | v5.x (map by name) | Connected-experience / cloud-content settings |
| **ISO 27001:2022** | 5.34, 8.12 | Privacy; data leakage prevention |

---

### 5.3 Disable Advertising, Tailored Experiences, and Activity Collection

**Profile Level:** L1 (Crawl)

**Track:** Both — consumer toggles plus policy/registry equivalents.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3 |
| NIST 800-53 | SI-12, PL-4 |

#### Description
Turn off the per-user data collection that feeds personalization and ads: the **advertising ID**, **tailored experiences** (diagnostic-data-driven tips/ads), **activity history**, **location** (device-wide or per app), and Start/Settings suggestion surfaces. These are consumer-facing and reachable on Home via Settings, with policy/registry equivalents for managed devices.

#### Rationale
**Why This Matters:**

- The advertising ID links app activity to a per-device identifier for ad targeting — disabling it is a clean, no-cost privacy win
- **Activity history is local-only since January 2024** (cloud sync deprecated; previously-synced data auto-deletes within 30 days) — turning it off and clearing it removes a local behavioral record
- Tailored experiences explicitly use "your Windows diagnostic data to offer you personalized tips, ads, and recommendations" — disabling it severs diagnostics from personalization
- Location has a device-wide off switch (admin) plus per-app control; note desktop apps are exempt from per-app control, so device-wide off is the stronger lever

**Attack Prevented (privacy):** Ad-targeting identifiers, diagnostics-driven personalization, behavioral/location history accumulation

#### ClickOps Implementation

**Consumer (Home/Pro) — all under Settings → Privacy & security:**
1. **General** (or **Recommendations & offers**): turn off "Let apps show me personalized ads by using my advertising ID", "Let websites show me locally relevant content…", "Let Windows improve Start and search results by tracking app launches", "Show me suggested content in the Settings app"
2. **Diagnostics & feedback → Tailored experiences** → Off
3. **Activity history** → turn off "Store my activity history on this device" and **Clear activity history**
4. **Location** → turn **Location services** Off device-wide (or manage per app), and clear location history

**Enterprise (policy/registry):**
1. Advertising ID: **System → User Profiles → "Turn off the advertising ID"** = Enabled (Privacy CSP `DisableAdvertisingId`)
2. Tailored experiences: **Windows Components → Cloud Content → "Do not use diagnostic data for tailored experiences"** = Enabled
3. Activity feed: registry `HKLM\Software\Policies\Microsoft\Windows\System` → `EnableActivityFeed = 0`, `PublishUserActivities = 0`, `UploadUserActivities = 0`

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="5.3" %}

#### Validation & Testing
1. Confirm the advertising ID toggle is off (registry `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo` → `Enabled = 0`)
2. Confirm activity history is off and cleared; confirm location services state matches policy

**Expected result:** Ad identifiers, tailored experiences, and activity/location collection are off across the device.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-12, PL-4 | Information handling; rules of behavior |
| **CIS Windows 11** | v5.x (map by name) | Privacy settings |
| **ISO 27001:2022** | 5.34 | Privacy and protection of PII |

---

### 5.4 Govern Recall and Copilot

**Profile Level:** L2 (Walk)

**Track:** Both — consumer defaults differ from managed-device defaults.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 3.3, 2.3 |
| NIST 800-53 | SI-12, CM-7 |

#### Description
Control the two AI surfaces that carry the largest privacy footprint. **Recall** (Copilot+ PCs) periodically snapshots and OCRs the screen into a local database; **Copilot** is an assistant app. On unmanaged consumer Copilot+ PCs, Recall is present but **opt-in per user** (off until you opt in); it can be removed entirely. On Enterprise/Education and Intune-managed devices, Recall is off by default and policy-controlled.

#### Rationale
**Why This Matters:**

- Recall's own researchers documented the risk plainly: the snapshot database has been shown extractable by a **standard user with no admin rights** (Alexander Hagenah's *TotalRecall*; Kevin Beaumont's analysis), and by design it "will not hide information such as passwords or financial account numbers" beyond its sensitive-information filter — so on a shared or compromised device it is a concentrated data-exposure surface
- Because consumer Recall is opt-in and removable, the privacy-maximizing choice is explicit: **leave it un-opted-in, or remove the feature** (`Disable-WindowsOptionalFeature … -FeatureName Recall -Remove`)
- The policy `WindowsAI/DisableAIDataAnalysis` ("turn off saving snapshots") and `WindowsAI/AllowRecallEnablement` ("remove Recall") are **available on Pro**, not just Enterprise/Education — so managed Pro fleets can enforce this
- The legacy `TurnOffWindowsCopilot` policy is **deprecated** and does not govern the current Copilot app; remove the app itself (`Remove-AppxPackage`) or use App Control/AppLocker

**Attack Prevented (privacy + security):** Bulk capture of on-screen credentials and sensitive content; standard-user extraction of the Recall database; unwanted AI data analysis

#### Prerequisites
- Recall applies only to Copilot+ PCs (NPU-class hardware); the AI policies require Windows 11 24H2 with the relevant KB

#### ClickOps Implementation

**Consumer:**
1. Leave Recall un-opted-in (default), or manage it at **Settings → Privacy & security → Recall & snapshots** (turn "Save snapshots" off, delete snapshots, keep sensitive-information filtering on)
2. To remove Recall entirely: **Turn Windows features on or off** → uncheck Recall (or use the pack's `Disable-WindowsOptionalFeature`)
3. Uninstall Copilot: **Settings → Apps → Installed apps → (Copilot) → Uninstall**

**Enterprise (policy — Pro-capable):**
1. Turn off Recall snapshots: **Computer/User Configuration → Windows Components → Windows AI → "Turn off saving snapshots for Recall"** = Enabled (`WindowsAI/DisableAIDataAnalysis`)
2. Remove Recall: **Windows Components → Windows AI → "Allow Recall to be enabled"** = Disabled (`WindowsAI/AllowRecallEnablement` = 0)

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="5.4" %}

#### Validation & Testing
1. Confirm Recall is off/removed: `Get-WindowsOptionalFeature -Online -FeatureName Recall` reports it disabled, or the policy registry value `SOFTWARE\Policies\Microsoft\Windows\WindowsAI\DisableAIDataAnalysis = 1`
2. Confirm the Copilot app is uninstalled (`Get-AppxPackage -Name Microsoft.Copilot` returns nothing)

**Expected result:** Recall is not saving snapshots (or is removed), and Copilot is governed to your policy.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-12, CM-7 | Information handling; least functionality |
| **CIS Windows 11** | v5.x (map by name) | Windows AI / Recall settings |
| **ISO 27001:2022** | 5.34, 8.12 | Privacy; data leakage prevention |

---

## 6. Network & Update Hardening

### 6.1 Harden the Windows Firewall

**Profile Level:** L1 (Crawl)

**Track:** Both — `wf.msc`/PowerShell locally; GPO for fleets.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.4, 4.5, 8.5 |
| NIST 800-53 | SC-7, AU-2 |

#### Description
Ensure the Windows Firewall is enabled on all three profiles (Domain, Private, Public) with a default-deny inbound posture, and turn on dropped-packet and successful-connection logging with a usefully large log.

#### Rationale
**Why This Matters:**

- The firewall "drops traffic that doesn't correspond to allowed unsolicited traffic" by default — confirming it is enabled on every profile closes the gap where a profile was disabled
- Logging is the difference between a firewall that blocks and a firewall you can investigate: the default 4 MB log is too small; Microsoft recommends at least 20 MB per profile
- Default-deny inbound with explicit, program-scoped Custom rules (rather than broad port-opens) shrinks the reachable attack surface

**Attack Prevented:** Unsolicited inbound connections, lateral movement, undetected network activity

#### ClickOps Implementation
1. Local console: **`wf.msc`** → confirm all three profiles are On with inbound "Block (default)"
2. Enterprise: **Computer Configuration → Policies → Windows Settings → Security Settings → Windows Firewall with Advanced Security**
3. Set per-profile logging on for dropped and allowed connections and raise the size to ≥20 MB

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="6.1" %}

#### Validation & Testing
1. `Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction` shows all profiles Enabled and inbound Block
2. Confirm log files at `%windir%\system32\logfiles\firewall\` are growing and sized ≥20 MB

**Expected result:** All firewall profiles enabled, default-deny inbound, logging on.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-7, AU-2 | Boundary protection; event logging |
| **CIS Windows 11** | v5.x (map by name) | Windows Firewall |
| **ISO 27001:2022** | 8.20, 8.15 | Network security; logging |

---

### 6.2 Harden SMB and Block Legacy NTLM

**Profile Level:** L2 (Walk)

**Track:** Both — the 24H2 controls apply across editions.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.8, 3.10 |
| NIST 800-53 | SC-8, IA-2 |

#### Description
Keep SMB signing required (the default on Windows 11 24H2 Enterprise/Pro/Education), audit for peers that don't support signing/encryption before enforcing, and — on 24H2+ — block NTLM on the SMB client. NTLM is deprecated (announced June 2024); NTLMv1 is removed in 24H2.

#### Rationale
**Why This Matters:**

- SMB signing defeats relay/tampering on file traffic; 24H2 makes it required by default, and the audit controls let you find non-compliant peers before enforcing more broadly
- NTLM is the mechanism behind a long line of relay attacks — including 2025's **CVE-2025-33073**, an NTLM-reflection-to-SYSTEM on domain-joined machines *without SMB signing enforced* — so signing enforcement and NTLM restriction are directly load-bearing
- Blocking NTLM on the SMB client removes the easiest coercion-and-relay path for lateral movement

**Attack Prevented:** SMB relay, NTLM reflection/relay to SYSTEM, downgrade to NTLMv1

#### Prerequisites
- Windows 11 24H2 for `BlockNTLM` on the SMB client and the SMB audit controls
- An audit period before enforcing NTLM blocking (legitimate NTLM dependencies must be allowlisted)

#### ClickOps Implementation
1. Confirm SMB signing required: **Local Policies → Security Options → "Microsoft network client/server: Digitally sign communications (always)"** = Enabled
2. Enable SMB signing/encryption auditing (24H2) to find non-compliant peers, then block NTLM on the client: **Network → Lanman Workstation → "Block NTLM (LM, NTLM, NTLMv2)"** = Enabled, with an exception list for any documented dependency

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="6.2" %}

#### Validation & Testing
1. `Get-SmbClientConfiguration | FL RequireSecuritySignature, BlockNTLM` and `Get-SmbServerConfiguration | FL RequireSecuritySignature` reflect the intended state
2. Review SMB audit events for peers lacking signing/encryption before broad enforcement

**Expected result:** SMB signing required, non-compliant peers identified, NTLM blocked on the SMB client with reviewed exceptions.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SC-8, IA-2 | Transmission integrity; authentication |
| **CIS Windows 11** | v5.x (map by name) | SMB / NTLM settings |
| **ISO 27001:2022** | 8.20 | Networks security |

---

### 6.3 Control Delivery Optimization and Update Currency

**Profile Level:** L2 (Walk)

**Track:** Both — DO peer settings apply broadly; update deferral is Pro+.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 7.3, 7.4 |
| NIST 800-53 | SI-2, SC-7 |

#### Description
Restrict **Delivery Optimization** peer-to-peer sharing (a bandwidth-and-privacy setting) and keep the device current. On Pro/Enterprise/Education, use Windows Update client policies to defer and stage updates for testing; on Home, keep automatic updates on and use pause sparingly. **Do not disable Windows Update** — Microsoft is explicit that this reduces security.

#### Rationale
**Why This Matters:**

- Delivery Optimization defaults to LAN peering with a 20 GB monthly internet-upload cap; setting `DODownloadMode = 0` (HTTP only) disables P2P entirely for privacy/bandwidth-sensitive environments, or restrict peers to the local subnet
- Staying current is a security control in its own right: the 2024 **Windows Downdate** research (Alon Leviev, CVE-2024-21302/38202) showed downgrade attacks that "unpatch" a fully-updated machine — timely patching and boot-path integrity are the countermeasures
- Enterprise deferral (feature updates up to 365 days, quality up to 30) lets you test before broad deployment without ever turning updates off

**Attack Prevented:** Exploitation of unpatched vulnerabilities, downgrade attacks; (privacy) uncontrolled P2P upload of update content

#### ClickOps Implementation

**Both — Delivery Optimization:**
1. Consumer: **Settings → Windows Update → Advanced options → Delivery Optimization** → turn off "Allow downloads from other PCs" (or limit to local network)
2. Enterprise (GPO): **Windows Components → Delivery Optimization → "Download Mode"** = HTTP Only (0), or Group (2)/LAN (1) with subnet peer restriction

**Enterprise — update staging (GPO):**
1. **Windows Components → Windows Update → Windows Update for Business → "Select when feature updates are received"** and "…Quality Updates…" to set deferral windows

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="6.3" %}

#### Validation & Testing
1. `Get-DeliveryOptimizationStatus` / confirm `DODownloadMode` registry value matches policy
2. Confirm the device is on a current, supported build and updates are installing (never disabled)

**Expected result:** P2P update sharing restricted to policy, updates deferred-but-flowing (enterprise) or automatic (consumer), Windows Update never disabled.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | SI-2, SC-7 | Flaw remediation; boundary protection |
| **CIS Windows 11** | v5.x (map by name) | Delivery Optimization / Windows Update |
| **ISO 27001:2022** | 8.8, 8.20 | Technical vulnerability management; network security |

---

## 7. Monitoring & Detection

### 7.1 Establish Endpoint Audit Logging and Detection

**Profile Level:** L2 (Walk)

**Track:** Both — audit policy is broadly available; SIEM forwarding is enterprise.

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 8.2, 8.5, 8.9 |
| NIST 800-53 | AU-2, AU-6, SI-4 |

#### Description
Turn on the audit events that make an endpoint investigable — process creation **with command line** (the 25H2 baseline enables Event ID 4688 command-line capture), Defender and ASR detections, and NTLM auditing — and, for enterprises, forward them to a SIEM (Microsoft Sentinel or equivalent).

#### Rationale
**Why This Matters:**

- Process-creation events with command lines are the single highest-value telemetry for detecting living-off-the-land attacks; the 25H2 Microsoft baseline turns this on specifically "to improve visibility into how processes are executed"
- Defender, ASR (Audit mode), and Network protection all emit events that are only useful if collected and reviewed — 3.1–3.3 produce the signal, this control captures it
- NTLM auditing (before blocking per 6.2) and Windows Firewall logging (6.1) complete the picture for lateral-movement and network investigations

**Attack Prevented:** Undetected intrusion, inability to reconstruct an incident, silent defender tampering (pairs with EDR-Freeze-class awareness)

#### Prerequisites
- Enterprise: a log pipeline (Windows Event Forwarding, Intune, or an agent to Sentinel/SIEM)
- Consumer: local Event Viewer review (no SIEM)

#### ClickOps Implementation

**Both — enable command-line in process creation (GPO/registry):**
1. **Computer Configuration → Administrative Templates → System → Audit Process Creation → "Include command line in process creation events"** = Enabled (auditing of Event ID 4688)

**Enterprise — forward to SIEM:**
1. Configure Windows Event Forwarding or the Sentinel/Defender connector to collect Security, Defender Operational, and firewall logs

**Time to Complete:** ~30 minutes (local); more for a SIEM pipeline

#### Code Implementation

{% include pack-code.html vendor="windows-11" section="7.1" %}

#### Validation & Testing
1. Trigger a benign process and confirm Event ID 4688 records the full command line
2. Confirm Defender/ASR events appear in `Applications and Services Logs → Microsoft → Windows → Windows Defender/Operational`
3. Enterprise: confirm events arrive in the SIEM

**Expected result:** Command-line-enriched process auditing on, security events collected (and forwarded, for enterprise).

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **NIST 800-53** | AU-2, AU-6, SI-4 | Event logging; audit review; monitoring |
| **CIS Windows 11** | v5.x (map by name) | Advanced audit policy |
| **ISO 27001:2022** | 8.15, 8.16 | Logging; monitoring activities |

---

## 8. Compliance Quick Reference

### Authoritative baselines (verified 2026-08-15)

| Source | Coverage | Version |
|--------|----------|---------|
| **CIS Microsoft Windows 11 Enterprise Benchmark** | Managed/domain or MDM-joined; profiles L1, L2, BitLocker (BL) | **v5.1.0** |
| **CIS Microsoft Windows 11 Stand-alone Benchmark** | Unmanaged/consumer devices | **v5.0.0** |
| **CIS Microsoft Intune for Windows 11 Benchmark** | Intune-managed | **v5.0.0** |
| **DISA Microsoft Windows 11 STIG** | Enterprise + Professional | **V2R8** |
| **Microsoft Windows 11 Security Baseline (SCT)** | GPO backups; Pro/Enterprise/Education | **25H2** |
| **Intune Security Baseline for Windows** | MDM-managed | **25H2** |

> **CIS numbering note:** the recommendation IDs (the 1.x–18.x series) shift between benchmark major versions, and the full benchmark PDFs require CIS registration. This guide maps to CIS by **benchmark name and version** rather than citing individual recommendation numbers that could not be fetch-verified from the primary PDF. Confirm specific IDs against the current downloaded benchmark before asserting them in an audit.
>
> **CISA / NSA:** CISA publishes no Windows 11-specific hardening guide and points to Microsoft's Security Compliance Toolkit baselines; no NSA Windows 11-named publication was verifiable at authoring time.

### NIST 800-53 Rev 5 summary

| Family | Controls in this guide |
|--------|------------------------|
| Access control | [1.3](#13-rotate-local-administrator-passwords-with-windows-laps) AC-6 |
| Audit & accountability | [6.1](#61-harden-the-windows-firewall), [7.1](#71-establish-endpoint-audit-logging-and-detection) AU-2, AU-6 |
| Configuration management | [1.1](#11-apply-a-microsoft-security-baseline-enterprise-or-harden-accounts-consumer), [2.3](#23-enable-smart-app-control-consumer) CM-2, CM-6, CM-7 |
| Identification & authentication | [1.2](#12-protect-sign-in-credentials-windows-hello-credential-guard-lsa-protection), [1.3](#13-rotate-local-administrator-passwords-with-windows-laps) IA-2, IA-5 |
| System & communications protection | [4.1](#41-encrypt-the-system-drive-bitlocker-or-device-encryption), [4.2](#42-govern-the-encryption-recovery-key), [6.1](#61-harden-the-windows-firewall)–[6.3](#63-control-delivery-optimization-and-update-currency) SC-7, SC-8, SC-12, SC-28 |
| System & information integrity | [2.1](#21-verify-secure-boot-and-tpm-20), [2.2](#22-enable-memory-integrity-vbshvci), [3.1](#31-harden-microsoft-defender-antivirus)–[3.3](#33-enable-controlled-folder-access-and-network-protection), [5.1](#51-set-diagnostic-data-to-the-lowest-your-edition-allows) SI-2, SI-3, SI-4, SI-7, SI-12 |

### The "zero telemetry" answer, summarized

| Edition | Diagnostic data floor | Realistic privacy target |
|---------|----------------------|--------------------------|
| **Enterprise / Education** | **Off** (`AllowTelemetry = 0`) | Policy-enforced zero diagnostic data + restricted-traffic baseline; residual = activation, CRL/OCSP |
| **Pro** | **Required** (`0` coerced to `1`) | Required floor + connected-experience policies + consumer toggles |
| **Home** | **Required** (`0` coerced to `1`) | Required floor + every Settings privacy toggle + Widgets/Spotlight/OneDrive off |

---

## Appendix A: Edition Feature Availability

| Control | Home | Pro | Enterprise | Education |
|---------|------|-----|------------|-----------|
| Security baseline (GPO/Intune) | ❌ | ✅ | ✅ | ✅ |
| Credential Guard | ❌ | ❌ | ✅ | ✅ |
| Diagnostic data "off" | ❌ | ❌ | ✅ | ✅ |
| BitLocker (full) | ❌ (Device Encryption only) | ✅ | ✅ | ✅ |
| Personal Data Encryption | ❌ | ❌ | ✅ | ✅ |
| Windows LAPS (usable) | ❌ (no domain/Entra join) | ✅ | ✅ | ✅ |
| Recall policy (DisableAIDataAnalysis) | ❌ | ✅ | ✅ | ✅ |
| Windows Spotlight master policy | ❌ | ❌ | ✅ | ✅ |
| ASR rules (via PowerShell) | ✅ | ✅ | ✅ | ✅ |
| Defender + tamper protection | ✅ | ✅ | ✅ | ✅ |
| Smart App Control | ✅ | ✅ | ✅ | ✅ |

---

## Appendix B: References

**Microsoft Tier 1 (all verified 2026-08-15):**

- [Windows security baselines](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines) · [Security Compliance Toolkit](https://learn.microsoft.com/en-us/windows/security/operating-system-security/device-management/windows-security-configuration-framework/security-compliance-toolkit-10)
- [Configure Windows diagnostic data](https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization) · [Policy CSP - System (AllowTelemetry)](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system) · [Diagnostic Data Viewer](https://learn.microsoft.com/en-us/windows/privacy/diagnostic-data-viewer-overview)
- [Manage connections from Windows to Microsoft services](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services)
- [Enable VBS/HVCI (memory integrity)](https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity) · [Credential Guard](https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/) · [Smart App Control](https://learn.microsoft.com/en-us/windows/apps/develop/smart-app-control/overview)
- [ASR rules reference](https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference) · [ASR configure](https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-configure) · [Tamper protection](https://learn.microsoft.com/en-us/defender-endpoint/prevent-changes-to-security-settings-with-tamper-protection) · [Controlled folder access](https://learn.microsoft.com/en-us/defender-endpoint/controlled-folder-access-configure) · [Network protection](https://learn.microsoft.com/en-us/defender-endpoint/enable-network-protection)
- [BitLocker](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/) · [BitLocker recovery](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/recovery-overview) · [Windows LAPS](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview)
- [Manage Recall](https://learn.microsoft.com/en-us/windows/client-management/manage-recall) · [Policy CSP - WindowsAI](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai) · [Policy CSP - Experience](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-experience) · [Policy CSP - Privacy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy)
- [Windows Firewall (command line)](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/configure-with-command-line) · [SMB signing](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing) · [Block NTLM on SMB](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-ntlm-blocking) · [Delivery Optimization reference](https://learn.microsoft.com/en-us/windows/deployment/do/waas-delivery-optimization-reference)

**Tier 2 baselines:**

- [CIS Microsoft Windows Desktop Benchmarks](https://www.cisecurity.org/benchmark/microsoft_windows_desktop) · [DISA Windows 11 STIG (V2R8)](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_MS_Windows_11_V2R8_STIG.zip) · [NIST NCP checklist](https://ncp.nist.gov/checklist/revision/6626)

**Tier 3/4 research (context for rationale):**

- [Windows Downdate downgrade attacks — Alon Leviev, SafeBreach](https://www.safebreach.com/blog/downgrade-attacks-using-windows-updates/) · [Recall analysis — Kevin Beaumont, DoublePulsar](https://doublepulsar.com/how-the-new-microsoft-recall-feature-fundamentally-undermines-windows-security-aa072829f218) · [CVE-2025-33073 NTLM reflection — Praetorian](https://www.praetorian.com/blog/cve-2025-33073-ntlm-reflection-one-hop/)

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-08-15 | Initial Windows 11 hardening guide — the repo's first OS guide. 18 controls across identity/credential protection, OS/boot integrity, attack-surface reduction, data protection, privacy/telemetry, network/update hardening, and monitoring, each dual-tracked for consumer (Home/Pro) and enterprise (Pro/Enterprise/Education) with edition-gated automation surfaces. Privacy section gives an honest, edition-scoped answer to "zero Microsoft telemetry": policy-enforced zero diagnostic data on Enterprise/Education, Required floor plus connected-experience restriction on Home/Pro. Every technical string (GPO paths, Policy CSP URIs, cmdlets, registry keys) traced to fetch-verified Microsoft documentation; CIS (Enterprise v5.1.0 / Stand-alone v5.0.0) and DISA STIG (V2R8) versions verified; Tier 3/4 research (Windows Downdate, Recall extraction, bitpixie, CVE-2025-33073, EDR-Freeze) folded into rationale. Authored by Claude Code (Opus 5). |

---

## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Windows 11 hardening evolves with each feature update — currency contributions (new baseline versions, changed policies, new AI surfaces) are especially welcome.
