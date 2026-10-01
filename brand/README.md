# firestore_odm brand

## Shared generator

CI uses the shared brand action pinned to `a6c81b4bcda66bf624f0a68e25e63b3c0ed043eb`.
The masters, tokens, pixel grids and provenance remain in this repository;
existing assets are unchanged by moving the generator. From the repository
root, run this self-contained recipe. Select `OPERATION=write` to regenerate
and verify, `OPERATION=check` to verify only, or `OPERATION=resnap` to
intentionally redraw the small favicon grids, regenerate and verify.

```sh
(
  set -eu
  OPERATION=write # Choose write, check or resnap before running.
  BRAND_SCRIPT="$(mktemp)"
  trap 'rm -f "$BRAND_SCRIPT"' EXIT
  curl --fail --location --output "$BRAND_SCRIPT" \
    "https://raw.githubusercontent.com/SylphxAI/.github/a6c81b4bcda66bf624f0a68e25e63b3c0ed043eb/.github/actions/brand/build.py"
  case "$OPERATION" in
    check) set -- --check ;;
    write) set -- ;;
    resnap) set -- --resnap ;;
    *) echo "Unknown brand operation: $OPERATION" >&2; exit 1 ;;
  esac
  if [ "$OPERATION" != check ]; then
    python3 -m pip install pillow numpy resvg-py
  fi
  python3 "$BRAND_SCRIPT" --brand-dir "$PWD/brand" --root "$PWD" "$@"
  if [ "$OPERATION" != check ]; then
    python3 "$BRAND_SCRIPT" --brand-dir "$PWD/brand" --root "$PWD" --check
  fi
)
```

Check mode needs only Python 3 and does not regenerate files. Each invocation
prepares and cleans up its own script; later references select an operation in
this recipe, rather than reusing its temporary path. A download, dependency,
regeneration or verification failure stops the recipe with a nonzero status.
Generated-file comments that name `brand/build.py` describe the historical
generator; they are preserved to keep the asset bytes and hashes unchanged.

This folder is the source of truth for the firestore_odm name and its artwork;
every surface copies from it and never keeps a redrawn copy. Rebuild and check
it with:

Use the [shared recipe](#shared-generator): select `OPERATION=write` to
regenerate, `OPERATION=resnap` to redraw grids as well, or `OPERATION=check`
to verify hashes and surface copies.

The brand is small on purpose. There is no logo mark yet, so the name is set in
type, and the only artwork is the README hero drawn by Mark.

## Name

- Running text, and every user-visible string, is `firestore_odm`: lower case,
  words joined by an underscore, exactly the pub.dev package name. The README
  heading, the docs site title and the hero all carry that spelling.
- The sibling packages take the same spelling with their own suffix:
  `firestore_odm_annotation`, `firestore_odm_builder`.
- No capitals appear anywhere in the name, and there is no logo image, so there
  is no capitals-only-in-the-logo form.
- No local-script or transliterated name exists; the repository is English-only.
- Operator: firestore_odm is operated by Sylphx Limited. That is a legal
  statement, not part of the brand.

## Files

| Need | File |
|---|---|
| The README hero (the banner at the top of `README.md`) | no file: Mark draws it from the URL in `README.md` (mark.sylphx.com, `type=aurora`, `theme=grape`) |
| Docs site social card and GitHub social preview | `og/firestore_odm-og.png` (the site serves the copy at `docs/public/og.png`) |
| Colour and type values | `tokens.json` (and the generated `tokens.css`) |
| The generator spec and the generator | `brand.json`, [shared generator](https://github.com/SylphxAI/.github/tree/a6c81b4bcda66bf624f0a68e25e63b3c0ed043eb/.github/actions/brand) |
| Where every file came from | `provenance.json` |

## Colours

| Token | Hex | Use |
|---|---|---|
| `ground` | `#0F0A1C` | the README hero's canvas |
| `ink` | `#F6F1FF` | the name and the description line on the hero |
| `accent` | `#8B5CF6` | first light pool in the hero art (violet) |
| `accent-2` | `#EC4899` | second light pool (pink) |
| `accent-3` | `#6366F1` | third light pool (indigo) |

The docs site defines no brand colours of its own: `docs/.vitepress/config.mjs`
uses the stock VitePress theme, and there is no theme folder. The tokens are
therefore exactly the roles the README hero uses, read from the hero SVG that
mark.sylphx.com serves.

## Type

The hero sets the name in Mark's text stack, Inter first, then the reader's
system sans (the full stack is the `font.body` token). The banner embeds no
font file, and neither does this repository: there are no licences to track and
nothing to install. The docs site and the README render in their own defaults
(VitePress's stack and GitHub's), which are not brand faces.

## Small sizes

Not applicable until a mark exists: this brand has no favicon, app-icon or
pixel grid, and `brand.json` has no `icon` block. The `apps/flutter_example`
app icons (Android, iOS, macOS, Windows, `web/favicon.png`) are Flutter's
default template icons, not brand artwork; they are left as they are.

## Clear space and minimum size

Not applicable until a mark exists. The hero is a full-width image and the OG
image is used at its own 1280x640 social size.

## Do / Don't

The repository has no design document, so there are no drawn-artwork rules yet.
Until the brand has a mark, the working rules are the ones recorded above:

- Do write the name exactly as the package writes it: `firestore_odm`.
- Don't add capitals, a camel-case form, or an abbreviation.
- Don't draw a mark, monogram or lockup for it. A new brand direction lands
  here first and gets a similarity check before any surface uses it.
- Don't present Sylphx Limited as part of the name.
- Don't suggest Google, Firebase or Flutter publishes or endorses the package
  (see Trademark).

## Surfaces

| Surface file | Brand file |
|---|---|
| `docs/public/og.png` | `og/firestore_odm-og.png` |

Surfaces still to move:

- `README.md` line 3, the hero: the artwork is drawn by Mark from that URL, so
  there is no file to move; the URL's `type` and `theme` are the brand choices
  and its colours are the tokens above.
- The GitHub repository social preview: a repository setting, not a file. Upload
  `og/firestore_odm-og.png` when the owner next sets repository settings.
- `apps/flutter_example/**` app icons: Flutter template icons, not brand
  artwork, so they stay.

## Provenance

`og/firestore_odm-og.png` is a 1280x640 raster master (no vector source) in
Mark's banner style. Every file's SHA-256 is in `provenance.json`.

## Trademark

Not registered; use ™ at most, never ®.

Firestore is a trademark of Google LLC; the name uses it to say what the
library works with.
