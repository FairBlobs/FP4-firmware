#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-factory-image.zip>"
    exit 1
fi

tmpdir=$(mktemp -d)
mount=$(mktemp -d)

cleanup() {
    set +e
    sudo umount "$mount"

    sudo dmsetup remove /dev/mapper/dynpart-*
    sudo losetup -d "$loopdev"

    sudo rmdir "$mount"
    sudo rm -r "$tmpdir"
}
trap cleanup EXIT

unzip -d "$tmpdir" "$1" images/NON-HLOS.bin images/super.img

### NON-HLOS.bin ###
sudo mount -o ro "$tmpdir"/images/NON-HLOS.bin "$mount"
cp "$mount"/image/adsp* .
cp "$mount"/image/cdsp* .
cp -r "$mount"/image/modem* .
cp "$mount"/image/venus* .
cp "$mount"/image/wlanmdsp.mbn .
sudo umount "$mount"

### super.img ###
simg2img "$tmpdir"/images/super.img "$tmpdir"/super.raw.img
rm "$tmpdir"/images/super.img

loopdev=$(sudo losetup --read-only --find --show "$tmpdir"/super.raw.img)
sudo dmsetup create --concise "$(sudo parse-android-dynparts "$loopdev")"

sudo mount -o ro /dev/mapper/dynpart-vendor_a "$mount"
cp "$mount"/firmware/a615_zap.b* .
cp "$mount"/firmware/a615_zap.mdt .
cp "$mount"/firmware/a619_gmu.bin .
cp "$mount"/firmware/a630_sqe.fw .
cp "$mount"/firmware/lagoon_ipa_fws.* .

# cleanup happens on exit with the signal handler at the top