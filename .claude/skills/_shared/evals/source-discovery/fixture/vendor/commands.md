# Client, daemon and managed policy — fictional snapshot

Source identity: `https://docs.relaymesh.invalid/reference/commands`; body captured successfully on 2026-11-04.

`relaymesh` is the first-party interactive client. `relaymesh version --json` reports its version; it does not set daemon security preferences or prove local state protection.

`relaymeshd` is the first-party service daemon. Its documented Linux flag `--seal-state` configures the protection described in the [feature reference](sealed-state.md). Set it through the supported service deployment configuration and restart the service after reviewing prerequisites and recovery.

On Windows and standalone macOS, the documented device policy key is `SealState`, with Boolean values. Deploy it through the customer's managed-device tooling and restart the service.

No central console toggle for enabling state protection exists. Reported state can be reviewed in the console Attributes panel. This reference covers local commands and system-policy settings.
