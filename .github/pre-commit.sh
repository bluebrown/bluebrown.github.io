#!/usr/bin/env bash

bash .github/generate.sh
if test -z "$(git status README.md --porcelain)"; then
	exit 0
fi

git add README.md
msg="[NOTICE] README.md has been updated. Please review and commit the changes."
printf "\n\033[0;33m%s\033[0m\n" "$msg"
exit 1
