# MSX-UNAPI tools

This directory contains the source of various UNAPI related tools. Looking at these may be useful for you if you want to develop an application that uses the routines provided by an UNAPI compliant API implementation; if you just want the binaries, head to the [releases](https://github.com/Konamiman/MSX-UNAPI-specification/releases) section.

* [apilist.asm](apilist.asm): This tool lists all the installed UNAPI implementations for a given specification identifier.

* [ramhelpr.asm](ramhelpr.asm): This is the source for two tools:
  * RAMHELPR.COM: Installs an UNAPI compatible RAM helper. To be used in MSX-DOS 2 and Nextor.
  * MSR.COM: Installs MSX-DOS 2 compatible mapper support routines and an UNAPI compatible RAM helper. To be used in MSX-DOS 1.

* [eth.c](eth.c): Control program for Ethernet UNAPI implementations.

* [tcpip.c](eth.c): Control program for TCP/IP UNAPI implementations.

To build the tools written in C you need [SDCC](https://sdcc.sourceforge.net/), and to build the tools written in assembler you need [Nestor80](https://github.com/Konamiman/Nestor80). You may want to take a look at [the Makefile](Makefile) for guidance.

Note also that [the SDCC libraries repository](https://github.com/Konamiman/SDCC-libraries-for-MSX) (a dependency for these tools) is added as [a git subodule](https://github.blog/open-source/git/working-with-submodules/) in the `lib/konamiman-sdcc` directory, if you find that `lib/konamiman-sdcc` is empty after you clone this repository, run `git submodule update --init --recursive`.
