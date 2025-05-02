#!/usr/bin/env bash
set -Eeuo pipefail

# take the revision from the current head
: "${GIT_REV:=$(git rev-parse HEAD)}"

# this cant be changed, unless the build script
# invocation below is also changed. its using
# relative path
dist=.github/dist

# add a worktree from the actual origin branch,
# enter it, and remove all contents.
git worktree add "$dist" origin/gh-pages
cd "$dist" || exit 1
git rm -rf .

# trigger the build script in the actual branch,
# which is in the parent dirtory. This populates
# add new content to the gh-pages branch
bash ../build.sh

# overwrite the old content in the branch
git add .
git commit --no-verify --amend --message "deploy: ${GIT_REV}"

# # force push to overwrite history in github
# git push --force origin gh-pages
#
# # clean up, so next time will run smooth
# cd - || exit 1
# git worktree remove --force "$dist"
