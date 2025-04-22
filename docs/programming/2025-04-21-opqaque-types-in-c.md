# Opaque Types in C

Opaque types are a way to hide the implementation details of a data
structure. This allows you to define a type without exposing its
implementation.

The caller has only a forward declaration of the type. This declaration
defines the behavior of the type as in function signatures, but not the
implementation.

This is similar to the concept of interfaces in other languages, such as
Go or Java. However, the concrete implementation must be linked at
compile time. So there can be only one implementation of the interface
in a given compilation unit. I am not sure if this is considered static
dispatch, but I think it is something along those lines.

Given a header file `log.h`.

```c
struct log;
struct log *log_new();
int log_info(struct log *, const char *);
void log_close(struct log *);
```

And a source file `main.c` consuming the header.

```c
#include "log.h"

int main() {
  struct log *log = log_new();
  log_info(log, "Hello, World!");
  log_close(log);
  return 0;
}
```

The main file is able to use the opaque type without knowing its
implementation.

One possible impkemnentation for `log.c` might look like
the below.

```c
struct log {
  FILE *file;
};

struct log *log_new() {
  struct log *lg = malloc(sizeof(struct log));
  lg->file = stderr;
  return lg;
}

int log_info(struct log *log, const char *msg) {
  return fprintf(log->file, "%s\n", msg);
}

void log_close(struct log *log) {
  fclose(log->file);
  free(log);
}
```
