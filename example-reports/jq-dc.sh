#!/usr/bin/env sh

echo $1
cat $1 | jq -r '.dependencies | map(.vulnerabilities?) | map(select(. != null)) | flatten ' | less
