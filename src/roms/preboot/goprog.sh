#!/usr/bin/env bash

PROG="/mnt/c/Gowin/Gowin_V1.9.12_x64/Programmer/bin/programmer_cli.exe"

pushd $(dirname $PROG)

${PROG} "$@"

popd