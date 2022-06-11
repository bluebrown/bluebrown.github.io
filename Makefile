bundle=bundle2.7

dev:
	$(bundle) exec jekyll serve --watch --drafts

build:
	$(bundle) exec jekyll build

update:
	$(bundle) update github-pages

install:
	$(bundle) install

info:
	$(bundle) exec github-pages versions

syntax:
	mkdir -p _sass
	$(bundle) exec rougify style github > _sass/syntax-light.scss
	$(bundle) exec rougify style monokai > _sass/syntax-dark.scss

lib:
	mkdir -p _includes/lib
	curl -fsSL https://github.com/allejo/jekyll-toc/releases/download/v1.2.0/toc.html > _includes/lib/toc.html
	curl -fsSL https://github.com/allejo/jekyll-anchor-headings/releases/download/v1.0.11/anchor_headings.html > _includes/lib/anchor_headings.html
