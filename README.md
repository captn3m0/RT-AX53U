# ASUS RT-AX53U Firmware Disassembly

Disassembly of the ASUS RT-AX53U Firmware. See [CHANGELOG.md](CHANGELOG.md) for release notes as per upstream changes.

## Process

The official firmware was downloaded, then extracted using `binwalk`. The complete squashfs-root was uploaded to this git-repository, with the commit timestamps as per the firmware timestamp.

The GitHub releases contain the TRX files, for verification purposes.

## Commands

### Firmware Download

Downloaded manually from [ASUS DL][dl] to the `fw` directory, and renamed to the tiniest version number (3.0.0.4.386_69061 is saved as `fw/69061.trx`).

### Firmware Extraction

```bash
cd fw;binwalk -e *.trx;cd ..
```

### Release Creation

```bash
for i in fw/*.trx; do \
	echo "$i" && \
	TAG=$(basename $i .trx) && \
	gh release create "3.0.0.4.386.$TAG" --generate-notes "$i#3.0.0.4.386.$TAG.trx" \
;done
```

### Commit Creation

```bash
for i in fw/*.trx; do \
	echo "$i" && TAG=$(basename $i .trx) && \
	cp -rf fw/_$TAG.trx.extracted/squashfs-root/*  . --no-dereference -p && \
	git add . && \
	GIT_COMMITTER_DATE="$(stat --format=%y $i)" git commit --date "$(stat --format=%y $i)" -m "ASUS RT-AX53U Firmware version 3.0.0.4.386.$TAG" && \
	GIT_COMMITTER_DATE="$(stat --format=%y $i)" git tag -a -m "3.0.0.4.386.$TAG" "3.0.0.4.386.$TAG"; \
done
```

## Links

- [Firmware Download: ASUS.com][dl]

[dl]: https://www.asus.com/networking-iot-servers/wifi-routers/asus-wifi-routers/rt-ax53u/helpdesk_bios?model2Name=RT-AX53U