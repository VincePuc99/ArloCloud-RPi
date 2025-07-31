#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CLIP_STORE="$SCRIPT_DIR/ArloExposed"
RETENTION_DURATION=14

find "$CLIP_STORE" -maxdepth 5 -type f -mtime +"$RETENTION_DURATION" -print | xargs -r rm
find "$CLIP_STORE"/arlo/metadata/ -type d -empty -delete
