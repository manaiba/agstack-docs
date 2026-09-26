---
title: Multi-repo documentation
linkTitle: Multi-repo docs
weight: 10
description: >
  How documentation from other AgStack repositories is pulled into this site, and
  how to add another repository.
---

## The mechanism

Each documented component repository is a **git submodule** under `external/`,
pinned to an exact commit. Hugo mounts that submodule's `docs/` directory into
`assets/`, and a **content adapter** turns the files into pages.

```
agstack-docs/
├── config/_default/hugo.toml              module mounts live here
├── external/
│   └── pancake/                           submodule, pinned by commit
│       └── docs/*.md                      upstream files, never edited here
├content/pancake/
│   ├── _index.md                          section index, authored here
│   └── _content.gotmpl                    adapter: files -> pages
└── layouts/
    ├── _markup/render-link.html           rewrites `*.md` cross-links
    └── _td-content-after-header.html      provenance banner
```

Reading order, once you want to change something:

1. `config/_default/hugo.toml` `[module]` — which submodule directory maps to which asset path.
2. `content/<name>/_content.gotmpl` — how files become pages (titles, order, slugs).
3. `layouts/_markup/render-link.html` — how repo-relative links are resolved.

## Why not mount straight into `content/`

The obvious wiring — mount `external/pancake/docs` to `content/pancake` — builds,
but every imported page comes out wrong. Upstream Markdown has no Hugo front matter,
and **Hugo does not derive a title from the filename**: `.Title` is simply empty. The
result is a blank `<title>`, an empty Docsy `<h1>` directly above the document's own
`# Heading`, and blank sidebar labels.

The three ways out are to add front matter to the component repo (which pushes Hugo's
`weight:` keys into a Java or Python repository), to override several Docsy templates
with a filename fallback, or to route the files through `assets/` and synthesise the
pages. This site does the third. The adapter reads each file's own first `# H1` as the
title and strips it from the body so Docsy's heading is the only one.

## Why not symlinks

The [kernelci.org](https://github.com/kernelci/kernelci-project) site — the best-known
example of this pattern — wires submodules in with tracked relative symlinks
(`content/en/components/kci-dev` → `../../../external/kci-dev/docs`). That works, but
symlinked *directories* inside `content/` are a fragile corner of Hugo that maintainers
have discussed removing outright, and that site is still pinned to Hugo 0.97.3. Module
mounts reach the same place through a supported path.

## Adding a repository

1. **Add the submodule**, tracking a branch so `make update` can follow it:

   ```bash
   git submodule add -b main https://github.com/agstack/<repo>.git external/<repo>
   ```

2. **Mount its docs into `assets/`** in `config/_default/hugo.toml`:

   ```toml
   [[module.mounts]]
     source = "external/<repo>/docs"
     target = "assets/imported/<repo>"
   ```

   Do not remove the `content` → `content` and `assets` → `assets` mounts above it.
   Declaring any mount for a component replaces Hugo's default for that component,
   so both of the site's own directories have to be listed explicitly or they vanish
   from the build — silently, since an absent mount is not an error. This bites
   hardest on `assets/`: the symptom is not a missing page but the theme's own
   stylesheet and logo quietly winning, because `assets/scss/_variables_project.scss`
   and `assets/icons/logo.svg` are simply not there to override them.

3. **Copy the adapter** and adjust the variables at the top — `$repo`, `$branch`,
   `$assetDir`, `$sectionDir`, and `$license`/`$licenseFile` — plus the `$order`
   list that controls sidebar order:

   ```bash
   mkdir -p content/<repo>
   cp content/pancake/_content.gotmpl content/<repo>/
   ```

   `$sectionDir` must match the adapter's own directory. It is what repoints Docsy's
   "View page source" and "Edit this page" links at the component repo; get it wrong
   and those links send readers to the adapter template instead of the Markdown they
   are reading.

   `$license` is the source repository's SPDX identifier. Imported pages are not
   covered by this site's CC BY-SA 4.0, so every page in the section states its own
   licence in the provenance banner — see [Licensing](../licensing/).

4. **Write a section index** at `content/<repo>/_index.md` with a `title`,
   `weight`, and a `description`. This file is authored here, not imported.

5. **Build and check** — `make check` fails on unresolved cross-links:

   ```bash
   make check
   ```

## Keeping imports fresh

A submodule pins a commit, so imported docs would otherwise stay frozen at whatever
the component repo looked like when it was added. Dependabot's `gitsubmodule`
ecosystem opens a weekly PR per submodule bumping the pointer; the diff is the
upstream documentation change, which makes it a useful editorial checkpoint. See
`.github/dependabot.yml`.

To bump everything by hand:

```bash
make update      # git submodule update --remote --merge
```

## Known costs

Worth knowing before adding the sixth repository:

- **Cross-link rewriting is heuristic.** `render-link.html` maps `FOO.md` to the slug
  the adapter would have produced. Links into subdirectories of a component's `docs/`
  tree are not handled — the adapter globs one level (`*.md`).
- **Images need their own mount.** The adapter handles Markdown only; a component repo
  with `docs/images/` needs a second mount into `static/`, and its relative image
  paths then no longer match. `pancake` has no images, so this scaffold does not
  demonstrate a fix.
- **Cloning without submodules fails quietly.** `git clone` alone yields an empty
  `external/`. The adapters call `errorf` on an empty mount to turn that into a build
  failure rather than a site with missing sections; `make init` and the CI workflow's
  `submodules: recursive` are the real fix.
- **No content transformation on the way in.** Unlike a sync script, mounts are
  read-only: badges, GitHub-specific admonitions and `README`-style intros arrive
  as-is. Heading levels in particular are upstream's: a document that uses `#` for
  every major section renders a page full of `<h1>`s, and the adapter only lifts
  the *leading* one.
- **Docsy's "Create child page" link is wrong on imported sections.** It prefills a
  Hugo front-matter stub into the component repo's `docs/` directory, which is
  exactly the coupling this setup avoids. The "View page source" and "Edit this
  page" links beside it are correct; only this one should be ignored.
- **`.File` is not nil on generated pages.** It points at the adapter template, so
  any theme feature keyed off `.File` needs the same remap treatment that
  `path_base_for_github_subdir` gives the repository links.
