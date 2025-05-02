#!/usr/bin/env bash
printf "# Index\n\n" >README.md
find . -name "*.md" ! -name "README.md" | sort -r | while read -r file; do
	name="${file:13:-3}"
	anchor="[${name//-/ }]($file)"
	echo "- $anchor" | tee -a README.md
done
