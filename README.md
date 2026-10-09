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
