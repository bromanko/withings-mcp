.PHONY: upstream dev typecheck build deploy format check clean

upstream:
	scripts/materialize-upstream

dev: upstream
	cd vendor/withings-mcp && bun run dev

typecheck: upstream
	cd vendor/withings-mcp && bun run typecheck

build: upstream
	cd vendor/withings-mcp && bun run build

deploy:
	scripts/deploy $(DEPLOY_HOST)

format:
	nix fmt

check:
	nix flake check

clean:
	rm -rf build vendor/withings-mcp
