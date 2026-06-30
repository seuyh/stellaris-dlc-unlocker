#!/bin/bash
copy_file() {
    cp "$1" "$2" || { echo "Error: Failed to copy $1 to $2"; exit 1; }
}

LIBSTEAM_API_DIR=$(find . -name "libsteam_api.so" -printf "%h\n" | head -n 1)
[ -z "$LIBSTEAM_API_DIR" ] && { echo "Error: libsteam_api.so not found."; exit 1; }
if [ ! -z "$CREAM_CONFIG_PATH" ]; then
    if [ ! -f "$CREAM_CONFIG_PATH/cream_api.ini" ]; then
        echo "Error: cream_api.ini not found in CREAM_CONFIG_PATH."; exit 1;
    fi
else
    if [ ! -f "$PWD/cream_api.ini" ]; then
        echo "Error: cream_api.ini not found in the current working directory."; exit 1;
    fi
fi
if [ -z "$CREAM_CONFIG_PATH" ] && [ "$LIBSTEAM_API_DIR" != "$PWD" ]; then
    export CREAM_CONFIG_PATH="$PWD/cream_api.ini"
fi

copy_file "$PWD/lib32Creamlinux.so" /tmp/lib32Creamlinux.so
copy_file "$PWD/lib64Creamlinux.so" /tmp/lib64Creamlinux.so
copy_file "$LIBSTEAM_API_DIR/libsteam_api.so" /tmp/libsteam_api.so

LD_PRELOAD="$LD_PRELOAD /tmp/lib64Creamlinux.so /tmp/lib32Creamlinux.so /tmp/libsteam_api.so" "$@"
EXITCODE=$?
rm -f /tmp/lib32Creamlinux.so /tmp/lib64Creamlinux.so /tmp/libsteam_api.so
exit $EXITCODE
