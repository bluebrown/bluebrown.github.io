---
author: Nico Braun
tags: [make, automation]
published: 2023-09-03
updated: 2025-04-21
date: 2023-09-03
---

# Effective Make

Make is a useful and versatile tool. It comes with almost every Linux
distribution and is often used for building software. However, it is
also a powerful tool for automating tasks.

## Clean Start

Make has many built-in rules and functionality that may cause unexpected
behavior. To avoid that, it is best to start with a clean slate. There
are a few [common
settings](./https://www.gnu.org/software/make/manual/html_node/Makefile-Basics.html)
that are often found at the top of a Makefile.

```Makefile
SHELL = /usr/bin/env bash
.SHELLFLAGS = -o errexit -o errtrace -o nounset -o pipefail -c
.SUFFIXES:
.DEFAULT_GOAL := help
```

## Concurrent Jobs

If you want to speed up your builds through concurrency, you need to
ensure the goals and prerequisites are structured such that running the
goals in concurrency does not cause trouble.

Below is an example. prerequisites, added to the goal's prerequisite
list (`goal: prereqs...`), should be able to run concurrently. If there
are prerequisites that need to run in sequence, they should be moved to
the goals body. Inside the body one can still run some prerequisites
concurrently, by invoking make with multiple goals.

```Makefile
all: a b c
    $(MAKE) d
    $(MAKE) e
    $(MAKE) f g
```

The order of execution, when concurrency is enabled, will be:

1. a, b and c
2. d
3. e
4. f and g

To enable concurrency, use the `-j` flag:

>```bash
>make -j $(nproc) all
># -j [N], --jobs[=N]  Allow N jobs at once; infinite jobs with no arg.
>```

This also means, that some script snippets, should be moved to its own
goal, so that it can be controlled with the concurrency primitives.

instead of:

```Makefile
work:
    cp a b
    echo c > d
    cat b d > e
```

do something like:

```Makefile
work: copy write
    cat b d > e

copy:
    cp a b

write:
    echo c > d
```

That will allow to run both, `cp` and `echo`, concurrently. Note how the
`cat` command, which depends on both tasks, is still in the goals body,
leading to it being executed after copy and write have been, potentially
concurrently, executed.

## Lazy Execution

Make was originally designed as a build system for C projects.
Therefore, a lot of its functionality revolves around files (and other
resources) the recipes produce. Make can determine if a goal is up to
date or needs to be rerun, based on change timestamps of the
prerequisites.

For example, if we change the above script to have the goals match the
file names the recipes produce, we can help make to know when a recipe
should be rerun.

```Makefile
e: b d
    cat b d > e

b: a
    cp a b

d:
    echo c > d
```

Note, how the `b` goal has a prerequisite to `a`, even though a is not a
goal. So prerequisites can also be local files. If they change, make
will rerun the recipe.

### Order Only Prerequisites

If you want to depend on a local folder, that will not work. As soon as
you create a file in the directory, the directory counts as updated, so
make will always re-run the recipe.

So if you have the below Makefile, you may be surprised to see that the
tools is downloaded again, every time the results.txt is produced.

```bash
results.txt: bin/tool
    bin/tool > results.txt

bin/tool: bin
    curl "https://my.org/tool" -o bin/tool

bin:
    mkdir -p bin
```

The solution to that is an [order-only
prerequisite](https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types).
Note the `|` before listing `bin` as prerequisite.

```bash
bin/tool: | bin
    curl "https://my.org/tool" -o bin/tool

bin:
    mkdir -p bin
```

This will ensure bin is created before bin/tool but without forcing the
target to bin/tool to be updated if bin changes.

## Automatic Variables

Make has a number of [automatic
variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)
that can be used in the recipes. They are set to the name of the target
or prerequisite that caused the recipe to be executed. This allows you
to write more generic recipes.

```make
concat: combined.txt

combined.txt: data/*.txt
    ls -la $(<D)
    echo "files that are newer than $(@F): $(?F)"
    cat $^ > $@
```

## Auto generate help text

In order to generate a help text for the makefile, the makefile can be
read with something like awk. In addition, comments can be used to
provide contextual information about a given goal. For example, the
`kubebuilder` projects generates an [arcane looking one
liner](https://github.com/kubernetes-sigs/kubebuilder/blob/679071485c9e5a4c5afc68897d8a715a1f113fa1/pkg/plugins/golang/v4/scaffolds/internal/templates/makefile.go#L115).

Below is a version inspired by that one liner. It is its own executable
script that can be called from the makefile. This help with readability.

```awk
#!/usr/bin/env -S gawk -f

BEGIN {
  use_theme_candyland()
  print_usage()
  # split targets and options
  FS = "(:.*##|?=)"
}

# options::  <var> ?= <default>
/^[a-zA-Z_]+\s\?=.*/ {
  printf("  %s%-20s%s%s (default:%s%s%s%s%s)%s\n",
    fg_option, $1, c_reset, fg_comment, c_reset,
    fg_value, $2, c_reset, fg_comment, c_reset)
}

# headings:: ##@ <subject>
/^##@/ { printf("\n%s%s:%s\n", fg_heading, substr($0, 5), c_reset) }

## subheadings:: ###@ <subject>
/^###@/ { printf("\n%s%s:%s\n", fg_subheading, substr($0, 6), c_reset) }

## targets:: <target>: ## <description>
/^[a-zA-Z_0-9\-\/]+:.*?##/ {
  printf("  %s%-20s%s%s%s%s\n", fg_target, $1, c_reset, fg_comment, $2, c_reset)
}

function print_usage() {
  printf("\n%sUsage:%s\n  %smake%s", fg_heading, c_reset, fg_binary, c_reset)
  printf(" %s[ command ]%s", fg_target, c_reset)
  printf(" %s[ option=%s%svalue%s%s ]...%s\n", fg_option,
    c_reset, fg_value, c_reset, fg_option, c_reset)
}

function use_theme_cargo() {
  c_reset = "\33[0m"
  c_bold = "\33[1m"
  c_green = "\33[32m"
  c_blue = "\33[34m"
  c_cyan = "\33[36m"
  c_white = "\33[37m"

  fg_binary = sprintf("%s%s", c_bold, c_cyan)
  fg_heading = sprintf("%s%s", c_bold, c_green)
  fg_subheading = sprintf("%s%s", c_reset, c_green)
  fg_target = sprintf("%s%s", c_bold, c_cyan)
  fg_option = sprintf("%s%s", c_bold, c_cyan)
  fg_value = sprintf("%s%s", c_bold, c_blue)
  fg_comment = sprintf("%s%s", c_bold, c_white)
}
```

This allows to write the documentation for the makefile in the makefile
itself.

```Makefile
##@ Options

GITHUB_SHA ?= $(shell git rev-parse main)
DOKTRI_AUTHROR ?= Nico Braun
DOKTRI_CHROMA_STYLE ?= tokyonight-moon

export DOKTRI_AUTHROR DOKTRI_CHROMA_STYLE

##@ Commands

help: $(CURDIR)/Makehelp ## show this help message
    @$< $(MAKEFILE_LIST)

dev: ## run the development server
    doktri serve
```

When invoking make with the defaut or `help` command, the help message
will be printed. The help message will look like this. Note that the
colors are not shown here, but they will be in the terminal.

```console
$ make

Usage:
  make [ command ] [ option=value ]...

Options:
  GITHUB_SHA           (default: $(shell git rev-parse main))
  DOKTRI_AUTHROR       (default: Nico Braun)
  DOKTRI_CHROMA_STYLE  (default: tokyonight-moon)

Commands:
  help                 show this help message
  dev                  run the development server
```
