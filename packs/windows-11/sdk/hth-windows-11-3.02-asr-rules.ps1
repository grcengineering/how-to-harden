# Control: 3.2 Enable Attack Surface Reduction (ASR) Rules
# Profile Level: L2 (Walk) | Track: Both (works on Home via PowerShell)
# Frameworks: NIST 800-53 SI-3/CM-7 | CIS Controls v8 10.5/9.4
# Guide: https://howtoharden.com/guides/windows-11/#32-enable-attack-surface-reduction-asr-rules
# Interface: Defender PowerShell (Add-MpPreference -AttackSurfaceReductionRules_*)
#   https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-configure
#   GUIDs from: https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference
# Requires Defender AV active mode + real-time + cloud protection on. Run elevated.
# Actions: 0/Disabled, 1/Block, 2/AuditMode, 5/NotConfigured, 6/Warn.

# HTH Guide Excerpt: begin ps-asr-standard-block
# The three "standard protection" rules Microsoft recommends enabling in Block
# without extensive testing:
$standard = @(
  '56a863a9-875e-4185-98a7-b882c64b5ce5',  # Block abuse of exploited vulnerable signed drivers
  '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2',  # Block credential stealing from LSASS
  'e6db77e5-3df2-4cf1-b95a-636979351e5b'   # Block persistence through WMI event subscription
)
Add-MpPreference -AttackSurfaceReductionRules_Ids $standard `
  -AttackSurfaceReductionRules_Actions Enabled,Enabled,Enabled
# HTH Guide Excerpt: end ps-asr-standard-block

# HTH Guide Excerpt: begin ps-asr-audit-then-block
# Other high-value rules - start in AUDIT (2), review events, then promote to Block (1).
$audit = @(
  'd4f940ab-401b-4efc-aadc-ad5f3c50688a',  # Block all Office apps from creating child processes
  'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550',  # Block executable content from email client and webmail
  'd3e037e1-3eb8-44c8-a917-57927947596d',  # Block JS/VBScript from launching downloaded executable content
  '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c'   # Block Adobe Reader from creating child processes
)
Add-MpPreference -AttackSurfaceReductionRules_Ids $audit `
  -AttackSurfaceReductionRules_Actions AuditMode,AuditMode,AuditMode,AuditMode

# Review configured state:
$p = Get-MpPreference
for ($i=0; $i -lt $p.AttackSurfaceReductionRules_Ids.Count; $i++) {
  "{0} => {1}" -f $p.AttackSurfaceReductionRules_Ids[$i], $p.AttackSurfaceReductionRules_Actions[$i]
}
# HTH Guide Excerpt: end ps-asr-audit-then-block
