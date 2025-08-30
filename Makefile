.PHONY: lint
lint:
	alejandra *.nix

.PHONY: check
check:
	nix flake check
