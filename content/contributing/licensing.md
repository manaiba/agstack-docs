---
title: Licensing
linkTitle: Licensing
weight: 20
description: >
  Which licence applies to which page, and why it depends on where the page
  was written.
---

{{% pageinfo %}}
Pages **authored in this repository** are [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
Pages **imported from a component repository** are covered by *that repository's*
licence, not this one. Every imported page names its licence in the banner at the
top.
{{% /pageinfo %}}

## Why there are two answers

This site is not the origin of everything it publishes. Some pages are written
here; others are the component repositories' own `docs/` directories, pulled in as
git submodules and rendered unchanged. Re-licensing someone else's documentation
by the act of displaying it would be both wrong and impossible — the licence
travels with the work, not with the renderer.

So the rule is simply: **a page keeps the licence of the repository it was written
in.**

## What applies where

| Content | Licence | Where it lives |
|---|---|---|
| Documentation authored in `agstack-docs` | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) | [`LICENSE`](https://github.com/agstack/agstack-docs/blob/main/LICENSE) |
| The site itself — layouts, shortcodes, SCSS, config, Docker and CI | [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) | [`LICENSE-CODE`](https://github.com/agstack/agstack-docs/blob/main/LICENSE-CODE) |
| Imported documentation | whatever its source repository says | that repository's own `LICENSE` |
| The AgStack name, logo and wordmark | trademarks of the Linux Foundation | not covered by either licence above |

Two licences for one repository is deliberate: CC BY-SA is written for prose and
is a poor fit for build tooling, while Apache-2.0 is written for code and says
nothing useful about documents. Splitting them keeps each doing the job it was
drafted for.

## Currently imported

| Section | Source repository | Licence |
|---|---|---|
| [PANCAKE](../../pancake/) | [`agstack/pancake`](https://github.com/agstack/pancake) | [EUPL-1.2](https://github.com/agstack/pancake/blob/main/LICENSE) |

Note that EUPL-1.2 is **not** CC BY-SA 4.0 and carries different obligations. If
you reuse material from an imported section, check that section's licence rather
than the site footer.

## Contributing

Opening a pull request against documentation in this repository means agreeing to
publish your contribution under CC BY-SA 4.0. Contributing to an imported section
means opening a pull request against *that* repository, under its terms.

When you add a new imported section, record its licence in the content adapter —
the `$license` and `$licenseFile` variables near the top — so the banner on every
page of that section states it. See
[Multi-repo documentation](../multi-repo/) for the rest of the wiring.
