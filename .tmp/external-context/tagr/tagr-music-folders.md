---
source: GitHub README / official repo
library: Tagr
package: tagr
topic: MUSIC_FOLDERS behavior and writable mounts
fetched: 2026-04-29T00:00:00Z
official_docs: https://github.com/suitux/Tagr
---

## Relevant guidance

- `MUSIC_FOLDERS` is a **comma-separated list of paths** to music directories.
- If unset, Tagr defaults to `/music`.
- Tagr scans recursively under the configured folders.
- You can restrict scanning by setting `MUSIC_FOLDERS` to only the subpaths you want scanned.
- Multiple host folders can be mounted under `/music` as subdirectories; Tagr scans those recursively.
- For editing metadata/artwork, the container/host paths must be **writable**, because Tagr writes tag changes directly back to audio files and manages cover art changes on disk.

## Exact env examples

Local:
```env
MUSIC_FOLDERS="/Users/youruser/Music,/Volumes/External/Music"
```

Docker:
```yaml
environment:
  - DATABASE_URL=file:/data/tagr.db
  - AUTH_SECRET=...
  - AUTH_USER=admin
  - AUTH_PASSWORD=...
  - MUSIC_FOLDERS=/music/library,/music/nas
volumes:
  - /home/user/Music:/music/library
  - /mnt/nas/Music:/music/nas
```

## Path caveats

- Use **absolute paths**.
- In Docker, mount the music dirs into the container path(s) you reference in `MUSIC_FOLDERS`.
- If you want to exclude folders, do **not** mount/include them in `MUSIC_FOLDERS`.

## Source links

- README: https://github.com/suitux/Tagr
- Docker compose example: https://github.com/suitux/Tagr/blob/main/docker-compose.yml
- Manual install section: https://github.com/suitux/Tagr#manual-installation
- Environment variables: https://github.com/suitux/Tagr#environment-variables
- Quick start / multiple folders note: https://github.com/suitux/Tagr#quick-start-with-docker
