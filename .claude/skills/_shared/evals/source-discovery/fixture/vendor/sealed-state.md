# Device identity state protection — fictional snapshot

Source identity: `https://docs.relaymesh.invalid/features/sealed-state`; body captured successfully on 2026-11-04. Feature introduced in 2025-06.

RelayMesh stores device identity keys locally. Protecting that state limits copying an enrolled identity to another machine. This is a RelayMesh setting, not whole-disk encryption.

| Platform / package | Supported configuration |
|---|---|
| Linux | `relaymeshd --seal-state`; requires a working TPM 2.0 |
| Windows | Boolean `SealState` managed-device policy; requires a working TPM 2.0 |
| Standalone macOS | Boolean `SealState` managed-device policy using the OS keystore |
| Store-distributed Apple client | OS-keystore protection by default |

For desktop releases 3.4–3.5 protection defaulted on. Since 3.6 it is opt-in on Linux and Windows; Apple-package behavior is unchanged. Consult [release notes](release-notes.md) for dates.

There is **no native graphical setting for enabling this feature**. See the [daemon and system-policy reference](commands.md). Applying a change requires a service restart. Unsupported hardware can prevent startup; a reset or lost protector can require reenrollment. Establish independent recovery before any rollout. This fixture authorizes no rollout.
