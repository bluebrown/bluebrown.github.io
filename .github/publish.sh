#!/usr/bin/env bash

: "${GIT_REV:=$(git rev-parse HEAD)}"

git worktree add .local/dist origin/gh-pages
cd .local/dist || exit 1
git rm -rf .

generate_index posts/
generate_pages posts/

git add .
git commit --amend -m "deploy: ${GIT_REV}"
git push --force origin gh-pages
cd - || exit 1
git worktree remove --force .local/dist
