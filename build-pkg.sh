#!/bin/sh
# build-pkg.sh — stage the mapfield release account into $1.
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
#   sh build-pkg.sh <stagedir>
#
# mapfield is BASIC only -- nothing to compile, nothing platform-specific in the tree
# -- so the SAME staged account is what udt, uv and jbase each install.  The
# per-platform part is the cataloging, which MVPKG does on the target.
#
# Hence `<sys>-any-any-le` artifacts built on a plain hosted runner: os/arch-
# locking a package with no native code would pin it to whichever machine
# packaged it, and taking a licensed container to copy a handful of files would
# put every release behind the one self-hosted runner udt, uv and jbase share.
# The endian stays `le` rather than `any` because that is the axis a compiled
# BASIC object would care about if this package ever grows one.
set -e
STAGE="${1:?usage: build-pkg.sh <stagedir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ACCT="$STAGE/mapfield"

mkdir -p "$ACCT/BP"
cp "$HERE"/BP/* "$ACCT/BP/"
if [ -d "$HERE/BP.DICT" ]; then mkdir -p "$ACCT/BP.DICT"; cp "$HERE"/BP.DICT/* "$ACCT/BP.DICT/"; fi
# EVERY STAGED SOURCE GETS A TRAILING NEWLINE.  UniVerse's compiler rejects a
# source whose last line is unterminated -- "End of File unexpected, Was
# expecting: ';', End of Line" -- and the repo's items do not all have one, so
# this is not cosmetic: without it the uv artifact cannot be compiled on the
# target at all, and the package installs as a directory of sources that never
# become programs.  Appending only when it is missing keeps re-staging
# idempotent.
for f in "$ACCT"/BP/*; do
   [ -f "$f" ] || continue
   [ -n "$(tail -c 1 "$f")" ] && printf '\n' >> "$f"
done

for f in PKG mvpkg.json LICENSE README.md .mvx .mv-account; do
   if [ -f "$HERE/$f" ]; then cp "$HERE/$f" "$ACCT/"; fi
done
echo "build-pkg: staged mapfield as $ACCT/"
