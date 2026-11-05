#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-3.6
#   guide: https://howtoharden.com/guides/claude-enterprise/#36-deploy-a-separate-desktop-device-policy
#   profile: L2
#   mode: read-only
#   requires: HTH_ORGANIZATION_ID, HTH_WORKSPACE_FOLDERS(JSON array of approved absolute folders), node(22+)
# Source: https://support.claude.com/en/articles/12622667-enterprise-configuration-for-claude-desktop
set -euo pipefail
# HTH Guide Excerpt: begin desktop-native-policy-generator
# Emits a real macOS .mobileconfig or Windows .reg payload to stdout. Does NOT install it.
# Usage: HTH_ORGANIZATION_ID=... HTH_WORKSPACE_FOLDERS='["/approved/work"]' bash this-file.sh macos
# Desktop policy is NOT com.anthropic.claudecode / managed-settings.json.
export HTH_POLICY_PLATFORM="${1:-macos}"
node --input-type=module - <<'JS'
import {randomUUID} from 'node:crypto';
const org=process.env.HTH_ORGANIZATION_ID;
if (!/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(org??'')) throw new Error('Expected an organization UUID');
const folders=JSON.parse(process.env.HTH_WORKSPACE_FOLDERS??'null');
if (!Array.isArray(folders)||!folders.length||folders.some(p=>typeof p!=='string'||!(/^(\/[^/]|[A-Z]:\\)/i.test(p))
  ||/[\r\n*?]/.test(p)||p.includes('..')||p==='/'||/^[A-Z]:\\?$/i.test(p))) throw new Error('Use explicit narrow absolute folders');
const settings={forceLoginOrgUUID:org,allowedWorkspaceFolders:folders,
  isDesktopExtensionEnabled:false,isDesktopExtensionDirectoryEnabled:false,isLocalDevMcpEnabled:false,
  disableAutoUpdates:false,autoUpdaterEnforcementHours:24};
// Optional local-VM EDR beta: an existing vendor-signed package, never downloaded or installed here.
if (process.env.HTH_EDR_PACKAGE || process.env.HTH_EDR_VENDOR) {
  const vendor=process.env.HTH_EDR_VENDOR, path=process.env.HTH_EDR_PACKAGE;
  if (!/^[a-z][a-z0-9_-]+$/.test(vendor??'') || !path || /[\r\n]/.test(path)) throw new Error('Provide the approved vendor ID and full signed-package path');
  settings.coworkEDRIntegration=path; settings.coworkEDRIntegrationVendor=vendor;
}
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const plist=v=>Array.isArray(v)?'<array>'+v.map(plist).join('')+'</array>':typeof v==='boolean'?`<${v}/>`
  :typeof v==='number'?`<integer>${v}</integer>`:typeof v==='string'?`<string>${esc(v)}</string>`
  :'<dict>'+Object.entries(v).map(([k,x])=>`<key>${esc(k)}</key>${plist(x)}`).join('')+'</dict>';
if (process.env.HTH_POLICY_PLATFORM==='macos') {
  if (folders.some(p=>!p.startsWith('/')) || settings.coworkEDRIntegration && !settings.coworkEDRIntegration.startsWith('/')) throw new Error('macOS paths must be absolute POSIX paths');
  const payload={PayloadContent:[{...settings,PayloadType:'com.anthropic.claudefordesktop',PayloadVersion:1,
    PayloadIdentifier:'com.howtoharden.claude.desktop.settings',PayloadUUID:randomUUID()}],
    PayloadType:'Configuration',PayloadVersion:1,PayloadIdentifier:'com.howtoharden.claude.desktop',
    PayloadUUID:randomUUID(),PayloadDisplayName:'HTH Claude Desktop baseline'};
  console.log('<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">'+plist(payload)+'</plist>');
} else if (process.env.HTH_POLICY_PLATFORM==='windows') {
  if (folders.some(p=>!/^[A-Z]:\\/i.test(p)) || settings.coworkEDRIntegration && !/^[A-Z]:\\/i.test(settings.coworkEDRIntegration)) throw new Error('Use full Windows drive paths');
  const quote=s=>String(s).replaceAll('\\','\\\\').replaceAll('"','\\"');
  const lines=['Windows Registry Editor Version 5.00','','[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Claude]'];
  for (const [k,v] of Object.entries(settings)) lines.push(typeof v==='boolean'||typeof v==='number'
    ?`"${k}"=dword:${Number(v).toString(16).padStart(8,'0')}`:`"${k}"="${quote(Array.isArray(v)?JSON.stringify(v):v)}"`);
  console.log(lines.join('\r\n')+'\r\n');
} else throw new Error('Platform must be macos or windows');
JS
# HTH Guide Excerpt: end desktop-native-policy-generator
