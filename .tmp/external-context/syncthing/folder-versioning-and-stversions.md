---
source: Syncthing docs
library: Syncthing
package: syncthing
topic: folder versioning and stversions
fetched: 2026-04-29T00:00:00Z
official_docs: https://docs.syncthing.net/users/versioning.html
---

## Short answer
- Yes, `.stversions` can be relocated outside the synced folder.
- The controlling setting is `folder.versioning.fsPath` in the folder config.
- If `fsPath` is empty, Syncthing uses `.stversions` inside the folder.
- `fsPath` may be absolute or relative.
- Relative `fsPath` is interpreted relative to the shared folder path when `fsType=basic`.

## Versioners
- `trashcan`: uses the version folder and supports `cleanoutDays`.
- `simple`: uses the version folder and supports `cleanoutDays` + `keep`.
- `staggered`: uses the version folder and supports `maxAge`.
- `external`: ignores `fsPath`, `fsType`, and `cleanupIntervalS`; version storage is handled by the command.

## Caveat
- If you set a custom version path, keep it on the same partition/filesystem as the folder path, or moves may fail.

## Practical guidance for Tagr / media tools
- Best option: move versions outside the media tree with `fsPath` to a hidden sibling or separate volume path.
- If your media tools scan recursively, exclude the version path explicitly.
- If you want maximum control, use `external` and store versions in a separate path that is not under the media folder.

## Source
- https://docs.syncthing.net/users/versioning.html
- https://docs.syncthing.net/users/config.html
