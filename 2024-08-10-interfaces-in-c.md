# Interfaces in C

C does not have a built-in concept of interfaces like some other
languages (e.g., Java, C#). However, you can achieve similar
functionality using function pointers and structures. This allows you to
define a common interface for different types and implement the methods
for each type separately.

Unfortunately, this involved a bit of null pointer juggling and
complicated type casting. This can be done as a one time operation
during initialization, so at least the actual methods have no null
pointer in their signature.

```c
#include <stdio.h>

typedef void Write(void *, char);

struct Writer {
  void *impl;
  Write *write;
};

void fprint(struct Writer w[static 1], const char *s) {
  while (*s)
    w->write(w->impl, *s++);
}

struct StandardOutput {};

void StandardOutput_write(struct StandardOutput w[static 1], char c) {
  fputc(c, stdout);
}

struct Buffer {
  char *data;
  size_t cap;
  size_t pos;
};

void Buffer_write(struct Buffer b[static 1], char c) {
  if (b->pos < b->cap)
    b->data[b->pos++] = c;
}

int main() {
  struct Writer stdw = (struct Writer){
      &(struct StandardOutput){},
      (Write *)StandardOutput_write,
  };

  struct Writer bufw = (struct Writer){
      &(struct Buffer){.data = (char[32]){0}, .cap = 32},
      (Write *)Buffer_write,
  };

  fprint(&stdw, "console meat\n");

  fprint(&bufw, "buffered beefalo\n");
  fprint(&stdw, ((struct Buffer *)bufw.impl)->data);
}
```
