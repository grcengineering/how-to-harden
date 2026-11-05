# Device posture reference — fictional snapshot

Source identity: `https://docs.relaymesh.invalid/posture`; body captured successfully on 2026-11-04.

| Attribute | Meaning |
|---|---|
| `node:releaseTrack` | Client release channel |
| `node:autoUpdate` | Built-in update preference |
| `node:stateSealed` | Product device-identity state is hardware/OS protected at rest |

The third signal relates to [device state protection](sealed-state.md). It reports a condition; adding a posture condition does not configure that protection. Missing required attributes do not match. Attribute support and what the protection actually does are documented on the linked feature page.
