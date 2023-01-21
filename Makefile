GITHUB_SHA ?= $(shell git rev-parse main)


dev:
	doktri serve --author 'Nico Braun'

publish:
	@git worktree add /tmp/gh-pages
	@git -C /tmp/gh-pages/ update-ref -d refs/heads/gh-pages
	@mv /tmp/gh-pages/.git /tmp/mygit
	@doktri build --dist /tmp/gh-pages/ --author 'Nico Braun' .
	@mv /tmp/mygit /tmp/gh-pages/.git
	@git -C /tmp/gh-pages/ add .
	@git -C /tmp/gh-pages/ commit -m "deploy $(GITHUB_SHA) to gh-pages"
	@git -C /tmp/gh-pages/ push --force --set-upstream origin gh-pages
	@git worktree remove /tmp/gh-pages --force
