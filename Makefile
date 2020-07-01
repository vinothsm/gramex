# Set the environment variable PYTHON to your custom Python exe
PYTHON ?= python

.PHONY: clean-pyc clean-build docs clean

BROWSER := $(PYTHON) -c "import os, sys; os.startfile(os.path.abspath(sys.argv[1]))"

help:
	@echo "test - run tests quickly with the default Python"
	@echo "release-test - all tests required for release (lint, docs, coverage)"
	@echo "push-pypi - upload package to pypi"
	@echo "stats - show code stats"
	@echo "push-docs - upload documentation to gramener.com"
	@echo "push-coverage - upload coverage stats to gramener.com"
	@echo "lint - check style with flake8, eclint, eslint, htmllint, bandit"
	@echo "docs - generate Sphinx HTML documentation, including API docs"
	@echo "release - package and upload a release"
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "clean-test - remove test and coverage artifacts"

clean: clean-build clean-pyc clean-test

clean-build:
	rm -rf build/
	rm -rf dist/
	rm -rf .eggs/
	rm -rf tests/uploads/
	rm -rf gramex-1.*
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -f .coverage
	rm -fr tests/htmlcov/
	rm -fr tests/.cache-url

lint:
	# Install packages using yarn (faster than npm)
	which yarn || npm install -g yarn
	# eslint requires eslint-plugin-* which are in package.json. yarn install them in THIS FOLDER (not globally)
	yarn add --dev eslint-plugin-html@6 eslint-plugin-template@0.4 eclint@2 eslint@7 htmllint-cli@0.0.7
	yarn install
	# eclint check files, ignoring node_modules
	find . -type f \( -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.yaml" -o -name "*.md" \) ! -path '*/node_modules/*' ! -path '*/_build/*' ! -path '*/htmlcov/*' ! -path '*/.eggs/*' -print0 | xargs -0 node_modules/.bin/eclint check
	node_modules/.bin/eslint --ext js,html gramex/apps
	# htmllint: ignore test coverage, node_modules, Sphinx doc _builds
	find . -name '*.html' | grep -v htmlcov | grep -v node_modules | grep -v _build | xargs node_modules/.bin/htmllint
	# Run Python flake8 and bandit security checks
	pip install flake8 pep8-naming flake8-gramex flake8-blind-except flake8-print flake8-debugger bandit
	flake8 gramex testlib tests
	bandit gramex --recursive --format csv || true    # Just run bandit as a warning

test:
	pip install nose nose-timer coverage
	$(PYTHON) setup.py nosetests
	# TODO: If we're on Travis and this is the master branch, rsync into learn.gramener.com/guide/coverage/<version>
	# TODO: Link to the coverage from the release notes
	# TODO: learn.gramener.com/guide/coverage/ should show the code coverage by release, and the reason

release-test: clean-test lint docs test

docs:
	rm -f docs/gramex* docs/modules.rst
	sphinx-apidoc -o docs/ gramex --no-toc
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	# TODO: Push to readthedocs AND the guide

release: clean
	$(PYTHON) setup.py sdist
	$(PYTHON) setup.py bdist_wheel

# TODO: Conda build
release-conda: release

# TODO: Docker build
release-docker: release
	docker build pkg/docker-py3 -t gramener/gramex:$VERSION
	docker tag gramener/gramex:$VERSION gramener/gramex:latest
	docker login                # log in as sanand0 / pratapvardhan
	docker push gramener/gramex

stats:
	# TODO: combine python and python setup
	@echo python
	@find gramex -path '*node_modules/*' -prune -o -name '*.py' | grep '\.py$$' | xargs wc -l | tail -1
	@echo python setup
	@wc -l docs/conf.py setup.py | tail -1
	@echo javascript
	@find gramex -path '*node_modules/*' -prune -o -name '*.js' | grep '\.js$$' | grep -v node_modules | xargs wc -l | tail -1
	@echo tests
	@find tests testlib -path '*node_modules/*' -prune -o -name '*.py' | grep '\.py$$' | xargs wc -l | tail -1

push-coverage:
	rsync -avzP tests/htmlcov/ ubuntu@gramener.com:/mnt/gramener/demo.gramener.com/gramextestcoverage/

push-docs: docs
	rsync -avzP docs/_build/html/ ubuntu@gramener.com:/mnt/gramener/learn.gramener.com/gramex/

push-pypi: release
	# Note: if this fails, add '-p PASSWORD'
	twine upload -u gramener dist/*

push-docker: release-docer

push-conda: release-conda

# TODO
# 	- Auto-generate the basis of a change log
