SHELL := $(shell which bash)
MINICONDA := $(CURDIR)/.miniconda3
CONDA := $(MINICONDA)/bin/conda
CONDA_VERSION := 4.11.0
VENV := $(PWD)/.venv
DEPS := $(VENV)/.deps
PYTHON := $(VENV)/bin/python
PYTHON_CMD := PYTHONPATH=$(CURDIR) $(PYTHON)
PROJECT_NAME=tournament_runner
PYLINT_CMD := $(PYTHON_CMD) -m pylint $(PROJECT_NAME) test

ifeq (Darwin,$(shell uname))
MINICONDA_OS=MacOSX
SP=" "
else
MINICONDA_OS=Linux
endif

ENVIRONMENT_YML:=environment-$(shell uname).yml

.PHONY: help
help:
	grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(CONDA):
	echo "Installing Miniconda3 to $(MINICONDA)"
	wget https://repo.anaconda.com/miniconda/Miniconda3-py39_$(CONDA_VERSION)-$(MINICONDA_OS)-x86_64.sh -O $(CURDIR)/miniconda.sh
	bash $(CURDIR)/miniconda.sh -u -b -p "$(CURDIR)/.miniconda3"
	rm $(CURDIR)/miniconda.sh

$(ENVIRONMENT_YML): | $(CONDA)

$(DEPS): $(ENVIRONMENT_YML)
	$(CONDA) env create -f $(ENVIRONMENT_YML) -p $(VENV) --force
	cp $(ENVIRONMENT_YML) $(DEPS)
	cat $(ENVIRONMENT_YML)

.PHONY: clean
clean:
	rm -rf $(VENV)
	rm -rf $(MINICONDA)
	find . -name __pycache__ | grep -v .venv | grep -v .miniconda3 | xargs rm -rf

.PHONY: test
test: $(DEPS)  ## Run tests
	$(PYTHON_CMD) -m pytest -v
	$(PYLINT_CMD)

.PHONY: watch
watch: $(DEPS) ## Run tests and linters continuously
	$(PYTHON_CMD) -m pytest_watch --runner $(VENV)/bin/pytest --ignore .venv -n --onpass '$(PYLINT_CMD)'

.PHONY: repl
repl: ## Run an iPython REPL
	$(VENV)/bin/ipython

.PHONY: solve
solve: | $(CONDA) ## Re-solve locked project dependencies from deps.yml
	rm -rf $(VENV)
	$(CONDA) env update --prune --quiet -p $(VENV) -f deps.yml
	$(CONDA) env export -p $(VENV) | grep -v ^prefix: > $(ENVIRONMENT_YML)
	cp $(ENVIRONMENT_YML) $(DEPS)

.PHONY: run
run: $(DEPS) ## Run the main function
	./run
