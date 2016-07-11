#!/bin/sh
cd "$(dirname "$0")" || exit
../../update-repo.sh ./repo.json "$@"
