# Bootloader

Traditionally, one would load some intiial code into the first sector of the
disk, and the BIOS would load this code into memory and execute it. This code
would then load the rest of the OS into memory and start it. This code is
called the bootloader.

Although a bit dated, and questionable at times, the <https://wiki.osdev.org>
page, is a good resource when it comes this learning 32 bit bootloaders in the
x86 architecture.

However, after some investigation, I decided to go with the `UEFI` bootloader
instead. The UEFI bootloader is a more modern bootloader that is used by most
modern operating systems.

## UEFI

There are a few things to keep in mind when working with the UEFI bootloader.
UEFI handles alot of the early boot processes. Actually all the way into long
mode. So whatever resource I come across, I have to keep in mind that I am in
64 bit mode. Inherently this also means, I need to use a [flat memory layout],
but more on that later.

That, however, does not mean that I dont have to do anything. The state UEFI
leaves the CPU in is not really usable for the kernel. So, I need to go back
and redo some of the work that UEFI has done, in a way that is more suitable
for the kernel and that allows for the kernel to take over.

UEFI also provides a minimal runtime environment the kernel can use. This means
for example that our archtirecture is not `freestanding`, but `uefi`. One can
think of this as having a minimal libc.

Additonally, UEFI provides a set of serices to interact with the hardware. One
can interact with these services through the `System Table`. The `System Table`
is a table that is passed to the kernel by the bootloader, and it contains
pointers to various services that the kernel can use.

For my kernel, I will opt out of all uefi services as the very first thing. I
am only interested in it providing a commmonly known entry point for the
kernel. As a bonus I am happy with already being in long mode.

## Choosing a Langauge

There are a few well known implementations of the UEFI APIs. The most well
known is the `gnu-efi` project. This project provides a set of headers that
define the UEFI APIs, and a set of libraries that implement the UEFI APIs.
There is also the `edk2` project, which is a more complete implementation of
the UEFI APIs. It was the first implementation of the UEFI APIs, and it is the
reference implementation of the UEFI APIs.

However, upon researching, I found that `zig`, which is specifically designed
for systems and embedded programming, has a implementation in the stdlib. There
are some examples here <https://github.com/nrdmn/uefi-examples>.

My uefi os loader is basicially just mashup of the examples, with some fixes
due to breaking changes in the zig stdlib. There is only one addition, that is
to call the kernel entry point.

```zig
const uefi = @import("std").os.uefi;
const fmt = @import("std").fmt;
const kmain = @import("kernel.zig").kmain;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;
    if (uefi.Status.Success != con_out.reset(false)) {
        return;
    }

    const boot_services = uefi.system_table.boot_services.?;
    var graphics: *uefi.protocol.GraphicsOutput = undefined;

    if (uefi.Status.Success != boot_services.locateProtocol(
        @ptrCast(&uefi.protocol.GraphicsOutput.guid),
        null,
        @ptrCast(&graphics),
    )) {
        return;
    }

    const fb: [*]u8 = @ptrFromInt(graphics.mode.frame_buffer_base);

    var memory_map: [*]uefi.tables.MemoryDescriptor = undefined;
    var memory_map_size: usize = 0;
    var memory_map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;

    while (uefi.Status.BufferTooSmall == boot_services.getMemoryMap(
        &memory_map_size,
        memory_map,
        &memory_map_key,
        &descriptor_size,
        &descriptor_version,
    )) {
        if (uefi.Status.Success != boot_services.allocatePool(
            uefi.tables.MemoryType.BootServicesData,
            memory_map_size,
            @ptrCast(&memory_map),
        )) {
            return;
        }
    }

    if (uefi.Status.Success == boot_services.exitBootServices(
        uefi.handle,
        memory_map_key,
    )) {
        kmain(fb);
        asm volatile ("cli");
        while (true) {
            asm volatile ("hlt");
        }
    }
}
```

This code is pretty much just boilerplate, to get to the kernel entry point. It
is interesting to note that the main function is actually linked as `efi_main`,
as this is the entry point for UEFI applications.
