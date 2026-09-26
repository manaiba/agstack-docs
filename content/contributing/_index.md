---
title: Contributing
linkTitle: Contributing
weight: 90
description: >
  How this site is built, and how to add documentation from another repository.
# Kept out of the project list on the landing page, which is introduced as "the
# projects that make up that infrastructure" — this is site meta, not a project.
# Still reachable from the sidebar on every page.
hide_summary: true
---

This site is a Hugo build using the [Docsy](https://www.docsy.dev/) theme. Content
comes from two places:

- **Authored here** — anything under `content/`, committed to `agstack-docs`.
- **Imported** — documentation that lives in a component repository's `docs/`
  directory and is pulled in as a git submodule. Those pages carry a banner naming
  their source repo, and edits go there rather than here.

See [Multi-repo documentation](multi-repo/) for the mechanism and for the steps to
wire in another repository.
