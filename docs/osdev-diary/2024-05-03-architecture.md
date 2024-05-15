# Archtecture

Most workstations and laptops will run some x86_64 architecture. This is the
most common architecture for personal computers, and it is what we will be
targeting.

Modern CPU can operate in different modes, and in oder to make use of the 64 bit
capabilities of the CPU, we need to switch to a particular mode called [long mode].

The x86_64 architecture has several modes of operation, but we will focus on the
following:

- [Real Mode]: This is the mode the CPU starts in. It is a 16-bit mode, and it
  is used to initialize the system. It is also used to load the bootloader and
  the kernel. It is a very simple mode, and it is not used for much else.

- [Protected Mode]: This is a 32-bit mode, and it is used by most modern
  operating systems. It provides memory protection, and it allows for
  multitasking. It is a more complex mode than real mode, and it is used by the
  bootloader to load the kernel.

- [Long Mode]: This is a 64-bit mode, and it is used by 64-bit operating
  systems. It provides access to the full 64-bit capabilities of the CPU, and it
  is the mode we will be using for our kernel.
