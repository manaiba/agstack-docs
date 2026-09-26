#!/bin/sh
# Bring the checkout to a buildable state, then hand off to the requested command.
#
# The goal is that `docker compose up serve` works on a bare `git clone` with no
# host-side setup at all: no Node, no Hugo, and no remembering to fetch
# submodules. Everything below is idempotent and cheap on a warm checkout.
set -e

# The repository arrives through a bind mount, so git sees host-owned files. The
# container runs as uid 1000 to match, but say so explicitly rather than relying
# on the host user happening to be 1000.
git config --global --add safe.directory /src 2>/dev/null || true

have_submodules() {
  [ -d /src/themes/docsy/theme/layouts ] && [ -d /src/external/pancake/docs ]
}

if ! have_submodules; then
  if [ ! -e /src/.git ]; then
    cat >&2 <<'EOF'
Submodules are missing and /src is not a git checkout, so they cannot be fetched.

The site's imported documentation lives in submodules under external/. Mount a
real clone of the repository, or run on the host:

    git submodule update --init --recursive

EOF
    exit 1
  fi

  echo "==> fetching submodules"
  if ! git submodule update --init --recursive; then
    cat >&2 <<'EOF'

Fetching submodules failed. This usually means the container has no network
access, or the repository was cloned over SSH without credentials available here
(.gitmodules uses https, so a fresh clone should not hit this).

Run it on the host and try again:

    git submodule update --init --recursive

EOF
    exit 1
  fi
fi

if ! have_submodules; then
  echo "submodules still missing after fetch; refusing to build an empty site" >&2
  exit 1
fi

# node_modules lives in the working tree, shared with the host. That is fine when
# both are linux/amd64, but hugo-extended and sass-embedded ship platform-specific
# binaries — so a node_modules installed on a macOS or Windows host would be
# present but unusable here. Test that Hugo actually *runs* rather than merely
# existing, and reinstall both trees if it does not.
if [ -x /src/node_modules/.bin/hugo ] && /src/node_modules/.bin/hugo version >/dev/null 2>&1; then
  if [ -z "$(ls -A /src/themes/docsy/theme/node_modules 2>/dev/null)" ]; then
    echo "==> installing Docsy theme dependencies"
    npm run install:theme-deps --prefix themes/docsy
  fi
else
  if [ -e /src/node_modules ]; then
    echo "==> existing node_modules cannot run here (likely built for another platform); reinstalling"
    rm -rf /src/node_modules /src/themes/docsy/theme/node_modules
  else
    echo "==> installing build toolchain (first run)"
  fi
  npm ci
  npm run install:theme-deps --prefix themes/docsy
fi

exec "$@"
