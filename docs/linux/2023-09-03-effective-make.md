# Effective Make

## Concurrent Jobs

If you want to speed up your builds through concurrency, you need to ensure the
goals and prerequisites are structured such that running the goals in concurrency
does not cause trouble.

Below is an example. prerequisites, added to the goal's prerequisite list (`goal:
prereqs...`), should be able to run concurrently. If there are prerequisites that
need to run in sequence, they should be moved to the goals body. Inside the body
one can still run some prerequisites concurrently, by invoking make with multiple
goals.

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
>make -j all
># -j [N], --jobs[=N]  Allow N jobs at once; infinite jobs with no arg.
>```

This also means, that some script snippets, should be moved to its own goal, so
that it can be controlled with the concurrency primitives.

instead of:

```Makefile
work:
  cp a b
  echo c > d
  cat b c > e
```

do something like:

```Makefile
work: copy write
  cat b c > e

copy:
  cp a b

write:
  echo c > d
```

That will allow to run both, `cp` and `echo`, concurrently. Note how the `cat`
command, which depends on both tasks, is still in the goals body, leading to it
being executed after copy and write have been, potentially concurrently,
executed.

## Lazy Execution

Make was originally designed as a build system for C projects. Therefore, a lot
of its functionality revolves around files (and other resources) the recipes
produce. Make can determine if a goal is up to date or needs to be rerun, based
on change timestamps of the prerequisites.

For example, if we change the above script to have the goals match the file
names the recipes produce, we can help make to know when a recipe should be
rerun.

```Makefile
e: b c
  cat b c > e

b: a
  cp a b

d:
  echo c > d
```

Note, how the `b` goal has a prerequisite to `a`, even though a is not a goal. So
prerequisites can also be local files.

### Order Only Prerequisites

If you want to depend on a local folder, that will not work. As soon as you
create a file in the directory, the directory counts as updated, so make will
always re-run the recipe.

So if you have the below Makefile, you may be surprised to see that the tools is
downloaded again, every time the results.txt is produced.

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

This will ensure bin is created before bin/tool but without forcing the target
to bin/tool to be updated if bin changes.
