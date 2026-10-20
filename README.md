# mapfield

`MAPFIELD` — the portable **`%MAP%` spec builder**. A *mapping* says how a
document's fields become MultiValue attributes; `MAPFIELD` builds one field of
that spec, and spec-driven codecs (`json`, and later `yaml`/`xml`) consume it to
turn Pick dynamic arrays into structured data and back.

```
SPEC<-1> = MAPFIELD(name, attr, conv, type, assoc)
```

builds `name<VM>attr<VM>conv<VM>type<VM>assoc`:

- **attr** — the MV attribute the field lands at.
- **type** — `TEXT`/`NUMERIC`/`DATE`/`TIME`; derived from **conv** when empty
  (`MD/MR/ML → NUMERIC`, `MT → TIME`, `D… → DATE`, else `TEXT`).
- **assoc** — empty = a single-valued (scalar) field; else the association name,
  whose members decode as **parallel multivalues** (an array of objects).

## `MAPSPEC` — the whole spec, from the dictionary

Building a spec field by field means restating, by hand, what the file's
dictionary already says. `MAPSPEC` reads it instead:

```
SPEC = MAPSPEC("CUSTOMERS", "")        every mappable D-item
SPEC = MAPSPEC("CUSTOMERS", FIELDS)    only these (@AM-delimited names)
```

The result is the same format `MAPFIELD` builds, so every consumer reads it
unchanged — and `MAPSPEC` calls `MAPFIELD` per field, so the conv → type
derivation has one implementation rather than two.

**Why it matters:** a hand-built spec is a second vocabulary — whatever names
that programmer chose, in that program. Taken from the dictionary, the names are
the file's own, so a `LIST`, the SQL projection, `json` and a template all say
`CUST.NAME` and mean the same thing. A field's default conversion is the one
`LIST` would use, because it is the same D-item.

Fields come back **sorted by attribute number**, so a spec mirrors the record's
layout and two runs over one dictionary agree — `SELECT` promises no order, and a
spec whose field order moves makes every encoded document differ for no reason.

### What it skips, and why

**Only D-items that name an attribute.** An I-descriptor is computed, not
stored; resolving one would mean evaluating the descriptor, which is a bigger
job and a route for a consumer to run arbitrary dictionary code. `PH` phrases
are not fields. Both are skipped — a stated limitation, not an oversight.

### The association attribute differs by platform, and this does not branch

```
mvx       1 D   2 attr#   3 conv   4 heading   5 format   6 assoc
udt/uv    1 D   2 loc     3 conv   4 name      5 format   6 S/M    7 assoc
```

They agree on 1–5 and diverge at 6: mvx puts the association there, UniData and
UniVerse put single/multi there and the association at 7. `MAPSPEC` takes it
from whichever of 7 and 6 carries a **name** — an association is never `S` or
`M`, which is exactly what the other layout puts there. One rule, no `$IFDEF`,
correct on both shapes without being told which it is reading.

## mvx vs the MV ports

On **mvx**, `MAPFIELD` is a **compiler builtin**, so this package does not ship
an mvx arm — it is built for **udt, uv and jbase** (`systems: udt uv jbase`), as
both manifests declare. A consumer that compiles on mvx as well selects with a
directive:

```basic
$IFDEF MVX
   * MAPFIELD is the compiler builtin — nothing to declare
$ELSE
   DEFFUN MAPFIELD(A, B, C, D, E)   ; * this package's cataloged function
$ENDIF
```

Pure BASIC — installs by cataloging `BP/MAPFIELD` (no native build).

## Consumers

`json` depends on `mapfield` (on udt); a `yaml` or `xml` package would too — one
shared projection layer, one parser each.
