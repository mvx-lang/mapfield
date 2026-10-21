#!/bin/sh
# mapfield — assert the in-tree manifests agree with each other and with the tag.
# Copyright (C) 2026 Gordon Heydon.  GPL-2.0-only (see LICENSE).
#
#   sh tests/manifest-version.sh <version>
#
# WHAT THIS CHECKS, AND WHAT IT NO LONGER DOES.  It asserts the two manifests
# AGREE -- with each other on the version, and with each other on the systems
# list.  It no longer has a job policing the version against the TAG, because
# the tag is now stamped into every staged artifact instead (mvx#363):
# publish-source for the source tarball, the account job for the three account
# tarballs.  So the in-tree version is derived, not authoritative.
#
# AN EARLIER VERSION OF THIS HEADER ARGUED THE OPPOSITE -- that checking beat
# stamping here, because the artifacts are staged in two places and one is
# outside this repo.  That was wrong twice over: both of those places stamp
# now, and three packages had already shipped wrong versions under the checking
# approach (json#28, mapfield#14, curl-cmd#22).  A check catches someone
# forgetting; a stamp removes the thing to forget.
#
# WHAT WENT WRONG BEFORE EITHER.  The published 1.1.0 artifact declared itself
# 1.0.0 (#14).  Measured from the release, not inferred:
#
#     mapfield-1.1.0-udt-any-any-le.tar.gz  ->  mvpkg.json "version": "1.0.0"
#                                               PKG line 2  1.0
#
# The two files did not even agree with each other -- "1.0" and "1.0.0" -- so
# there was no single stale number to notice.  THAT disagreement is what this
# script still exists for: stamping writes one version into both files and so
# cannot detect that they disagreed about anything else, and a systems list
# that differs between them ships in every artifact (json#38).
#
# Nothing resolves against these fields (mvpkg takes versions from the registry
# and the store inventory, and reads only name, description, deploy and
# dependencies from a manifest), which is exactly why the drift shipped: the
# only thing that reads them back is MVPKG info on a stored manifest.
set -eu
WANT="${1:?usage: manifest-version.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rc=0

# A rolling dev tag is not a version and is not expected to match.
case "$WANT" in
  dev|latest) printf 'manifest-version: %s is not a version tag - skipped\n' "$WANT"; exit 0 ;;
esac

if [ -f "$ROOT/mvpkg.json" ]; then
  got=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ROOT/mvpkg.json" | head -1)
  if [ "$got" = "$WANT" ]; then
    printf '  ok   mvpkg.json version is %s\n' "$WANT"
  else
    printf '  FAIL mvpkg.json says "%s", not "%s"\n' "$got" "$WANT"; rc=1
  fi
fi

# PKG is a line-oriented manifest: 1 name, 2 version, 3 description, 4 systems.
# ONE SPELLING OF THE NUMBER.  This compares the literal text, so "1.0" does not
# pass for "1.0.0" -- which is the drift that hid the stale version, since
# neither file looked wrong beside the other.
if [ -f "$ROOT/PKG" ]; then
  got=$(sed -n '2p' "$ROOT/PKG" | tr -d ' \r')
  if [ "$got" = "$WANT" ]; then
    printf '  ok   PKG line 2 is %s\n' "$WANT"
  else
    printf '  FAIL PKG line 2 says "%s", not "%s"\n' "$got" "$WANT"; rc=1
  fi
fi

# AND THE SYSTEMS LISTS MUST AGREE, for the same reason the versions must.  Both
# files ship in every artifact, and json shipped a release whose two manifests
# named different system sets (json#38) because only one of them was updated
# when an arm was dropped.  Nothing resolves against PKG's copy, which is what
# lets it survive a release.
sysline=$(sed -n '4p' "$ROOT/PKG" 2>/dev/null | tr -s ' \r' ' ' | sed 's/^ *//;s/ *$//')
sysjson=$(sed -n '/"systems"/,/]/p' "$ROOT/mvpkg.json" 2>/dev/null \
          | sed -n 's/.*"\([a-z0-9_]*\)".*/\1/p' | grep -v '^systems$' | tr '\n' ' ' \
          | sed 's/ *$//')
if [ -n "$sysline" ] || [ -n "$sysjson" ]; then
  if [ "$sysline" = "$sysjson" ]; then
    printf '  ok   both manifests declare the systems "%s"\n' "$sysline"
  else
    printf '  FAIL PKG line 4 says "%s", mvpkg.json says "%s"\n' \
           "$sysline" "$sysjson"; rc=1
  fi
fi

if [ "$rc" -ne 0 ]; then
  printf 'manifests: make both files say %s\n' "$WANT" >&2
fi
exit "$rc"
