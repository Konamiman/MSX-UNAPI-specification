# MSX-UNAPI tools

This directory contains the source of various UNAPI related tools. Looking at these may be useful for you if you want to develop an application that uses the routines provided by an UNAPI compliant API implementation; if you just want the binaries, head to the [releases](https://github.com/Konamiman/MSX-UNAPI-specification/releases) section.

* [apilist.asm](apilist.asm): This tool lists all the installed UNAPI implementations for a given specification identifier.

* [ramhelpr.asm](ramhelpr.asm): This is the source for two tools:
  * RAMHELPR.COM: Installs an UNAPI compatible RAM helper. To be used in MSX-DOS 2 and Nextor.
  * MSR.COM: Installs MSX-DOS 2 compatible mapper support routines and an UNAPI compatible RAM helper. To be used in MSX-DOS 1.

* [eth.c](eth.c): Control program for Ethernet UNAPI implementations.

* [tcpip.c](eth.c): Control program for TCP/IP UNAPI implementations.

Note that the tools written in C use [ASMLIB](https://github.com/Konamiman/MSX/tree/master/SRC/SDCC/asmlib) and also `crt0msx_msxdos_advanced`, `printf_simple` and `putchar_msxdos` from [Konamiman's MSX page](https://www.konamiman.com/msx/msx-e.html#sdcc).
