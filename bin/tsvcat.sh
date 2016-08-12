#!/bin/sh

find "$1" -name \*tsv | head -1 | xargs head -1
find "$1" -name \*tsv | xargs tail -q -n +2
