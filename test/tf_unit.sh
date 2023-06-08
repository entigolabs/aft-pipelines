#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/.."
cd $SCRIPTPATH || exit 1


docker run -it --rm -v "$(pwd)":"/app" -w /app/test test go test -v -timeout 30m