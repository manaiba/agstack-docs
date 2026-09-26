# Build/preview container for the docs site.
#
# Hugo is deliberately NOT installed here. `npm ci` pulls the exact hugo-extended
# version pinned in package.json, so this container, GitHub Actions and a local
# checkout all build with the same binary — one place to bump it, no drift between
# "works in Docker" and "works in CI".
#
# Node 24 / npm 11.18 are Docsy v0.17's stated minimums.
FROM node:24-bookworm-slim

# git is not needed to build the site (enableGitInfo is off), but the entrypoint
# reports on submodule state and contributors expect it to exist in the shell.
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# uid 1000, matching the typical host user, so everything written into the bind
# mount — node_modules, public/, resources/, and the fetched submodules — stays
# owned by the person running docker rather than by root.
USER node

EXPOSE 1313

# The entrypoint is read from the bind mount rather than copied into the image, so
# editing it takes effect on the next `docker compose up` with no image rebuild.
# The image is useless without the mount anyway — it carries no site content.
#
# Invoked through `sh` rather than executed directly, so it does not depend on the
# execute bit surviving however the tree reached the host (archive extraction, a
# copy across filesystems, a Windows checkout).
ENTRYPOINT ["/bin/sh", "/src/docker-entrypoint.sh"]
CMD ["npm", "run", "serve"]
