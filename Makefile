.DEFAULT_GOAL := help
.PHONY: help init serve build clean update check

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

init: ## Fetch submodules and install the toolchain (run this first)
	git submodule update --init --recursive
	npm ci
	npm run install:theme-deps --prefix themes/docsy

serve: init ## Serve locally at http://localhost:1313/
	npm run serve

build: init ## Build the production site into public/
	npm run build

check: build ## Build and fail on any broken internal reference
	@! npx hugo --minify --printPathWarnings 2>&1 | grep -iE '^WARN.*(render-link|content adapter)' \
	  || (echo "broken imported links or adapter warnings above" && exit 1)

update: ## Bump imported-docs submodules to the tip of their tracked branch
	@# Scoped to external/ on purpose. themes/docsy is pinned to a release tag, and
	@# an unscoped --remote would drag it to the tip of main instead.
	git submodule update --remote --merge -- external
	@echo
	@echo "Submodule pointers moved. Review with: git diff --submodule=log"

clean: ## Remove build output
	rm -rf public resources .hugo_build.lock

# No docker-* targets here on purpose: `docker compose up serve` is self-contained
# (the entrypoint fetches submodules and installs the toolchain), so wrapping it in
# make would only add a layer. See the Docker section of README.md.
