#!/usr/bin/env bash

cd "$(readlink -f "$0" | xargs dirname)/.." || exit 1

dist=".github/dist"
mkdir -p "$dist"

echo "# Index" >"$dist/index.md"

for file in *.md; do
	name="${file:11:-3}"
	md -html "$file" "$dist/$name.html"
	echo "- [${name/-/ }](./$name.html)" >>"$dist/index.md"
done

md -html "$dist/index.md"
rm "$dist/index.md"
