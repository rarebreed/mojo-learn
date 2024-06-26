# How programs use memory

I started writing this with the intention of just talking about the stack, heap, rgisters, and how low-level system
programming languages like mojo or rust need to think about memory.  Although I had a familiarity with how memory works
from my old hardware days working on linux device drivers, I realized two things: a lot of knowledge had slipped my mind
over time, and I would need to explain about more than just the stack, heap and registers.  This is doubly true for mojo
which, unlike any mainstream language, treats SIMD and address spaces as first class citizens.

So this presentation will be broken down into two parts.  The first will cover how an operating system (or even bare
metal devices) segment memory and why an OS has virtual memory.  It will also contain some basic information on how a
program is actually loaded when you call it.  This will be the part that briefly talks about how programs are compiled 
and linked.  The second part will cover the aforementioned stack, heap and regissters, including details on caches, and
why memory access is so costly.  Finally, it will cover how this all fits into the notion of "pass by value)copy)" and
"pass by reference".

## Part 1: How programs are built

If you never learned how programs actually get built, loaded and executed, or forgot about it, I will briefly explain
several concepts:

- compilation
- intermediate representations (IR) and assembly
- machine instructions
- linking
- loading/executing

[TODO insert a pic of the pipeline of events]

Even languages like java or python run on applications that take raw source code (like python) or a pre-compiled IR like
java bytecode and do many of the same steps that a compiled languages code would do but at runtime.  In order to make
things a little less general and abstract I will focus on arm64 (aka aarch64) architecture running on linux, that 
generates ELF format binaries (ie executables, .o, .so, .a, etc)

### Compiling source code

Ultimately, a computer runs on a combination of:

- A CPU
- memory
- IO devices (eg storage, GPIO, USB, etc)
- other (eg, a GPU is both an IO device, and what is called a hardware accelerator)
- *Operating System
- low-level libraries to interface with the OS or bare metal (eg libc)

> An Operating system is technically not necessary, but it does make many things easier.  This article will only refer 
> to systems with an OS, but some of what will be covered is still relevant even on bare metal devices (bare metal in 
> the pre-virtualization sense, meaning "without an operating system", not "a non-virtual computer")

So the question is, "how does the computer go from human readable source code, to something the system executes?".  The
first piece of the puzzle is compiling source code 