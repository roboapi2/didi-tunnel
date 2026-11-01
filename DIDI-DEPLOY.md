# Didi Tunnel deployment

This is the experimental Community edition, not yet fully tested.

## Install on a clean Linux test server (root)

Requires Go >= 1.23, GitHub access, and a systemd-based distribution.

```bash
curl -fsSL https://raw.githubusercontent.com/roboapi2/didi-tunnel/main/install.sh -o install-didi.sh
bash -n install-didi.sh
HASHEM_SOURCE_REF=main bash install-didi.sh
```

The `HASHEM_SOURCE_REF` is important: it makes the installer build the Go panel
from this repository's main branch instead of fetching a release from elsewhere.

## Verify on Linux

```bash
/usr/local/bin/gre-panel license check backhaul; echo $?
/usr/local/bin/gre-panel license check sentinel; echo $?
/usr/local/bin/gre-panel license check cluster; echo $?
hashem show-panel-url
```

All former Pro capability checks should return `0`. The API and actual
end-to-end tunnel behavior still require functional testing. The web panel
retains session authentication and CSRF requirements.

## Upgrade warning

Do not run an ordinary release-channel updater until you have published and
verified the new project's release artifacts. Use source-based installation
on disposable test hosts first.