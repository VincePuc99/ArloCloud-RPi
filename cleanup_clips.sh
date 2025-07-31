#!/bin/bash
CLIP_STORE="$(dirname "$0")/ArloExposed"
RETENTION_DURATION=14

find "$CLIP_STORE" -maxdepth 5 -type f -mtime +"$RETENTION_DURATION" -print | xargs -r rm
find "$CLIP_STORE"/arlo/metadata/ -type d -empty -delete
