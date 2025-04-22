SHELL = /usr/bin/env bash
.SHELLFLAGS = -o errexit -o errtrace -o nounset -o pipefail -c
.DEFAULT_GOAL := help
.SUFFIXES:

##@ Options

GITHUB_SHA ?= $(shell git rev-parse main)
DOKTRI_AUTHROR ?= Nico Braun
DOKTRI_CHROMA_STYLE ?= dracula

export DOKTRI_AUTHROR DOKTRI_CHROMA_STYLE

##@ Commands

help: $(CURDIR)/Makehelp ## show this help message
	@$< $(MAKEFILE_LIST)

dev: ## run the development server
	doktri serve

publish: ## publish the documentation
	git worktree add /tmp/gh-pages
	git -C /tmp/gh-pages/ update-ref -d refs/heads/gh-pages
	mv /tmp/gh-pages/.git /tmp/mygit
	doktri build --dist /tmp/gh-pages/ .
	mv /tmp/mygit /tmp/gh-pages/.git
	git -C /tmp/gh-pages/ add .
	git -C /tmp/gh-pages/ commit -m "deploy $(GITHUB_SHA) to gh-pages"
	git -C /tmp/gh-pages/ push --force --set-upstream origin gh-pages
	git worktree remove /tmp/gh-pages --force
