.DEFAULT_GOAL := help

# Create a virtual environment using uv with Python 3.12
uv:
	@curl -LsSf https://astral.sh/uv/install.sh | sh

.PHONY: fmt
fmt:  uv ## Run autoformatting and linting
	uvx pre-commit run --all-files

.PHONY: help
help:  ## Display this help screen
	@echo -e "\033[1mAvailable commands:\033[0m"
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' | sort

.PHONY: clean
clean: ## clean the repo from temp files
	@git clean -X -d -f
