#!/usr/bin/env bash

mkdir -p $1-memdump && cd "$_"

# dump memory
grep rw-p /proc/$1/maps \
| sed -n 's/^\([0-9a-f]*\)-\([0-9a-f]*\) .*$/\1 \2/p' \
| while read start stop; do \
    gdb --batch --pid $1 -ex \
        "dump memory $1-$start-$stop.dump 0x$start 0x$stop"; \
done

for file in $(ls $1-*.dump) ; do
    cat $file >> all.dump
done

rm -f $1-*.dump
cd ..
