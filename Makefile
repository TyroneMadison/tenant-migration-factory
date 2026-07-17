PYTHON ?= python3
export PYTHONPATH := orchestrator

.PHONY: help install test validate waves render checklist tf-validate

help:
	@echo "Targets: install, test, validate, waves, render, checklist TENANT=<id>, tf-validate"

install:
	$(PYTHON) -m pip install -r orchestrator/requirements.txt

test:
	$(PYTHON) -m pytest tests -q

validate:
	$(PYTHON) -m migrate_factory.cli validate

waves:
	$(PYTHON) -m migrate_factory.cli plan-waves

render:
	$(PYTHON) -m migrate_factory.cli render

checklist:
	$(PYTHON) -m migrate_factory.cli checklist $(TENANT)

tf-validate:
	@for dir in terraform/aws terraform/azure; do \
		echo "== $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false > /dev/null; \
		terraform -chdir=$$dir validate; \
	done
