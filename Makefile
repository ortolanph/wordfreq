NAME     := wordfreq
ZIG      ?= zig
ARGS     ?= sample.txt 10
BIN      := zig-out/bin/$(NAME)

# Cross-compilation targets: `make dist` builds all of them
TARGETS  := x86_64-linux-musl aarch64-linux-musl aarch64-macos x86_64-macos x86_64-windows

.DEFAULT_GOAL := build
.PHONY: build release run test fmt fmt-check dist clean help

build: ## Debug build -> zig-out/bin/wordfreq
	$(ZIG) build

release: ## Optimized build (ReleaseFast)
	$(ZIG) build -Doptimize=ReleaseFast

run: ## Build and run: make run ARGS="sample.txt 5"
	$(ZIG) build run -- $(ARGS)

test: ## Run all test blocks
	$(ZIG) build test --summary all

fmt: ## Format sources in place
	$(ZIG) fmt src build.zig

fmt-check: ## Fail if sources are not formatted (good for CI)
	$(ZIG) fmt --check src build.zig

dist: ## Small static binaries for every target in dist/<target>/
	@for t in $(TARGETS); do \
		echo "==> $$t"; \
		$(ZIG) build -Doptimize=ReleaseSmall -Dtarget=$$t --prefix dist/$$t || exit 1; \
	done

clean: ## Remove build artifacts and caches
	rm -rf zig-out .zig-cache dist

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | \
		awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'