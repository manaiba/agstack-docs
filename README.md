# agstack-docs

Documentation site for [AgStack](https://github.com/agstack) projects — Hugo +
[Docsy](https://www.docsy.dev/), deployed to GitHub Pages.

Documentation that lives in a component repository's `docs/` directory is pulled in
as a git submodule and mounted into the content tree, so it is written and reviewed
next to the code it describes. Everything else is authored here.

## Quick start

```bash
git clone --recurse-submodules https://github.com/agstack/agstack-docs.git
cd agstack-docs
make serve          # http://localhost:1313/
```

If you already cloned without `--recurse-submodules`, `make serve` will fix it —
`make init` runs `git submodule update --init --recursive` first. Without the
submodules the build fails loudly rather than publishing empty sections.

Requirements: Node ≥ 24 and npm ≥ 11.18. Hugo itself is pinned in `package.json`
(`hugo-extended`) and installed by `npm ci`, so there is nothing to install globally.

> The deployed site is a GitHub Pages *project* site, so its `baseURL` carries the
> `/agstack-docs/` path — and a Hugo server serves from whatever path `baseURL`
> has. `config/development/hugo.toml` overrides it back to the root for local use,
> which is why the local site is at `http://localhost:1313/` while the published
> one is under `/agstack-docs/`. `hugo server` picks up that override
> automatically; `hugo` (and CI) build with the production value.

| Target | What it does |
|---|---|
| `make init` | Fetch submodules, install Hugo and theme dependencies |
| `make serve` | Live-reloading server on :1313 |
| `make build` | Production build into `public/` |
| `make check` | Build and fail on unresolved imported cross-links |
| `make update` | Bump imported-docs submodules to their tracked branch tip |

## With Docker instead

Needs no Node and no Hugo on the host — only Docker with Compose v2 or later.
Nothing else to run first: a bare `git clone` is enough.

```bash
git clone https://github.com/agstack/agstack-docs.git
cd agstack-docs
docker compose up serve                  # http://localhost:1313/
```

| Command | What it does |
|---|---|
| `docker compose up serve` | Live-reloading server on :1313 |
| `docker compose run --rm build` | Production build into `./public` |
| `docker compose down` | Stop the server |
| `docker compose build` | Rebuild the image (only needed if the `Dockerfile` changes) |

Notes worth knowing:

- **Submodules are fetched for you.** The entrypoint runs
  `git submodule update --init --recursive` inside the container against the bind
  mount when `external/` or the theme is missing, so cloning without
  `--recurse-submodules` is fine. If that is not possible — no network, or `/src`
  is not a git checkout — it exits 1 explaining what to run, rather than building
  a site with silently empty sections.
- **Hugo is not baked into the image.** The Dockerfile is plain `node:24` and runs
  `npm ci`, which installs the exact `hugo-extended` pinned in `package.json`. The
  container, CI and a local checkout therefore build with the same binary, and the
  version is bumped in one place.
- **The first run is slow.** It fetches submodules and downloads the Hugo binary.
  Later runs reuse both, because `node_modules/` lives in the working tree rather
  than in a container volume. To start over, `rm -rf node_modules`.
- **`node_modules/` is shared with the host.** On Linux that is a feature — install
  once, use either path. If it was installed on a macOS or Windows host, the
  platform-specific `hugo-extended` and `sass-embedded` binaries will not run in
  the container; the entrypoint detects that (it checks Hugo actually runs, not
  just that the file exists) and reinstalls automatically.
- **Nothing comes back root-owned.** The container runs as uid 1000, so the
  fetched submodules, `node_modules/`, `public/` and `resources/` all stay
  editable on the host. The `Dockerfile` also avoids named volumes for this
  reason: Docker creates a volume's mountpoint inside the bind mount as root,
  which is enough to break both the submodule checkout and `npm ci`.
- **Editing `docker-entrypoint.sh` needs no image rebuild** — it is read from the
  bind mount, not copied into the image.
- **SELinux hosts need the `:z` mount flag**, which `docker-compose.yml` sets. A
  checkout under `$HOME` is labelled `user_home_t`, which container processes are
  not allowed to read, so without it the mount fails with `Permission denied`
  even though every file is world-readable. `:z` relabels the tree to
  `container_file_t`; note that this changes the labels on your working copy.
- **If your host account is not uid 1000**, put `APP_UID` and `APP_GID` in a
  `.env` file next to `docker-compose.yml` so files written into the mount stay
  yours:

  ```
  APP_UID=1001
  APP_GID=1001
  ```

### Troubleshooting

| Symptom | Cause |
|---|---|
| `cannot open /src/docker-entrypoint.sh: Permission denied` | SELinux, and the `:z` flag was removed or the file is mounted some other way |
| Files in `public/` owned by someone else | `APP_UID`/`APP_GID` do not match your host account |
| `hugo: not found`, or Hugo exits immediately | `node_modules` installed on a different platform — delete it and re-run |
| A production build in `public/` has root-relative URLs and unminified CSS | `docker compose up serve` is still running; its watcher rebuilt `public/` with the development config. Stop it first. |

## What is wired in

| Section | Source | Wiring |
|---|---|---|
| `/pancake/` | [`agstack/pancake`](https://github.com/agstack/pancake) `docs/` (9 files) | submodule → Hugo mount → content adapter |
| `/inatrace/` | authored here | placeholder; the INATrace repos have no `docs/` tree yet |
| `/contributing/` | authored here | local |

`pancake` is deliberately the only live import: it and `palefire` are the only AgStack
repositories today with a substantial `docs/` directory. Everything else documents
itself in a `README.md`, which is a content problem rather than a pipeline problem.

## Adding a repository

See [`content/contributing/multi-repo.md`](content/contributing/multi-repo.md),
which also records the known costs of this approach. The short version is four steps:
add the submodule, add a module mount into `assets/imported/<repo>`, copy the content
adapter, write a section index.

## Layout

```
config/
├── _default/hugo.toml                      config; [module] mounts wire in submodules
└── development/hugo.toml                   local-only: serve from / instead of /agstack-docs/
assets/
├── icons/logo.svg                          navbar mark, monochrome (currentColor)
└── scss/_variables_project.scss            brand palette, taken from the logo
static/                                     full lockup, colour mark, favicons
content/                                    sections live at the root: the site IS the docs
├── _index.md                               landing page + documentation index
├── contributing/multi-repo.md              how the pipeline works
├── inatrace/_index.md                      placeholder section
└── pancake/
    ├── _index.md                           section index (authored here)
    └── _content.gotmpl                     content adapter (imported files -> pages)
external/pancake/                           submodule, pinned by commit
layouts/
├── _markup/render-link.html                rewrites `*.md` cross-links to permalinks
└── _td-content-after-header.html           provenance banner on imported pages
themes/docsy/                               submodule, pinned to v0.17.0
.github/
├── workflows/pages.yml                     build + deploy (needs submodules: recursive)
└── dependabot.yml                          weekly submodule pointer bumps
Dockerfile                                  node:24 base; Hugo comes from npm ci
docker-compose.yml                          `serve` and `build` services
docker-entrypoint.sh                        installs deps, guards on empty submodules
```

## Deployment

`.github/workflows/pages.yml` builds on every push and pull request and deploys `main`
to GitHub Pages. Before the first deploy, set **Settings → Pages → Source** to
**GitHub Actions**.

`baseURL` in `hugo.toml` is set to `https://agstack.github.io/agstack-docs/`. To serve
from a custom domain such as `docs.agstack.org`, change `baseURL`, add the domain in
Settings → Pages, and create the DNS record. Note that `agstack.org` itself is not
GitHub Pages — it is WordPress — so only a subdomain is in play. Set the custom domain
on **this repository**, not on an `agstack.github.io` org-site repo: a domain set there
is inherited by every project site in the organisation.

## License

A page keeps the licence of the repository it was written in — this site renders
other projects' documentation, and displaying a document does not re-license it.

| Content | Licence |
|---|---|
| Documentation authored here (`content/`) | [CC BY-SA 4.0](LICENSE) |
| The site itself — `layouts/`, `assets/`, `config/`, Docker, CI | [Apache-2.0](LICENSE-CODE) |
| Documentation imported from a component repository | that repository's licence — currently [EUPL-1.2](https://github.com/agstack/pancake/blob/main/LICENSE) for PANCAKE |

Imported pages state their licence in the banner at the top of every page, driven
by `$license` in that section's content adapter. The full explanation is at
[`content/contributing/licensing.md`](content/contributing/licensing.md).
