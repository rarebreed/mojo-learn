# How programs use memory

I started writing this with the intention of just talking about how the stack, heap, cache and registers affect the
performance of a language.  Although I had a familiarity with how memory works from my old hardware days working on
linux device drivers, I realized two things:  a lot of knowledge had slipped my mind over time, and I would need to talk
about more than just the stack, heap and registers.  This is doubly true for mojo which, unlike any mainstream language,
treats SIMD and address spacess as first class and explicit citizens.

So this presentation will be broken down into three parts.  The first part will describe how programs go from human
readable source code, to machine code that actually executes on the computer system. The second will cover how an
operating system (or even bare metal devices) segment memory and why an OS has virtual memory.  It will also contain
some basic information on how a program is actually loaded when you call it.  This will be the part that briefly talks
about how programs are compiled and linked.  The second part will cover the aforementioned stack, heap and registers,
including details on caches, and why memory access is so costly.  Finally, it will cover how this all fits into the
notion of "pass by value)copy)" and "pass by reference".

## Why you should care

I wanted to stress again why I am going over the low-level details of how programs and memory interact.

As the computer and software industry has evolved, we have gone from languages that basically required you to know how
the machine worked, to more abstracted languages that lets you focus on your domain problem rather than worry about how
the machine actually ran your code.  However, with Big Data and Deep Learning becoming a "must have" to be competitive
in almost any industry, the computing horse power that is needed to run Deep Learning training and inference is making
us come back full circle and requiring a move back high performance code and therefore understanding how our language
generates the code that actually runs on the computer.

One of the dirty and not much talked about secrets of AI is how energy intensive it is.  It is on track to become like
bitcoin mining; in other words, it is becoming unsustainable.  Data centers are being stretched to their limits.  It is
not just a matter of adding more Nvidia or AMD GPUs.  The power draw on these GPUs are so much, that the data centers
may not even have enough the infrastructure to deliver the power even if it was available.  And even if there is enough
"green energy" to feed the energy wasteful GPUs, then there's the problem of controlling the waste heat that is
generated.  Also, until we get a truly renewable and clean source of energy, many forms of so-called green energy have
their limitations.  For example, solar requires certain rare earth metals that are non-renewable, we need to solve
disposal/renewal of blades in wind turbines, and some companies will claim they are Green by continuing to use fossil
fuels, but buying carbon credits as an offset (which is kind of like saying you'll jog 5 miles to have that brownie
sundae).

All of this begs issues with the environment and climate change.  It is an issue I have been trying to champion that we
as engineers need to be much more concerned with. As an industry, computing is starting to rival the airline industry in
terms of energy use (and damage to the climate). That's not a good sign for our industry.  We should be better stewards
and be mindful of how much resources our applications use.

Python has been used because it is easy for data scientists to learn, but it is slow.  The dirty truth is that most of
the heavy lifting for python is done in lower level languages like C++ (eg numpy, pytorch) or rust (eg polars or daft).
This is why I am very excited for mojo, because it will lift at least some of the burden of slow performing python code
off our compute instances.  Even though a lot of Deep Learning code is done through these faster python packages that
run low-level languages, there's still a lot of "glue" code that is pure python.  Also, the data cleaning and prep is
typically done in spark which runs on the JVM and has its own issues (ie, glutton for RAM often causing OOMs, garbage
collectors that cause wasteful pauses, etc).

[Insert a pic of a "dirty" data center]

In order to help alleviate the power and performance problem, we need to go back and learn from first principles.  That
means understanding how our programs actually get run by computer systems and not just hand wave it all away and let a 
language do a lot of black box magic inside a virtual machine or interpreter.

As a side bonus, you will become a better troubleshooter and debugger once you understand how a program actually works
under the hood.

## Part 1: How programs work

I realized while writing this article that a lot of people may have never learned how programs actually get built, 
loaded and executed. Or they learned it once in school and never had to think about it again.  So, I will briefly go 
over several important steps in how programs actually work "under the hood"

- compilation
- Intermediate Representation (IR) and assembling
- machine instructions (aka codegen or code generation)
- linking
- loading/executing

Along the way, I'll have to explain a few other concepts like an Operating System's system calls.  All of these topics
in and of themselves are worthy of a book, so I will only give the briefest of explanations so the reader will be aware
of how all this fits together when it comes to how programs run, especially with regards to memory.

As an aside, even non-compiled languages or JIT'ed languages such as python and java respectively actually do several
steps of the above.  For example, instead of compiling to assembly, Java compiles to .class files, containing Java
bytecode that then run on a virtual machine that actually generates machine code on the fly.  Python also has a virtual
machine (and is getting an experimental JIT in 3.13) that converts source to python bytecode (.pyc) that gets assembled
to python opcodes that gets executed by the python VM.  It's important to understand that the JVM and pyton interpreter
are themselves just binaries that run a program just like a native system language.

### Compilation

While we often say "The code got compiled" to mean the entire process of generating an executable or a library component
, the compilation step is just the first of many steps.  It is unfortunate that this meaning has taken hold, because the
other phases of building binaries gets lost.

The very first step in our journey is to take the source code we write in our language and convert it into another form.
In order to do this, there are two key components: determining the individual tokens (ie, the variables, keywords,
symbols, operands, etc), and figuring out the syntax between the tokens (ie, parsing).  The first step is usually called
lexing or tokenizing, and the latter step is usually called parsing. In most languages, the first step is relatively
easy, and the second step typically is done by building up grammar rules to build an abstract syntax tree (AST).

[show a pic of code transforming to tokens]

Parsing is a very complicated subject and concerns things about your language design called Context Free Grammars. If
you have ever looked at LLVM and seen the term SSA (Static Single Assignment) this is in some ways a kind of CFG,
because you can convert from an SSA <-> CFG  The reason CFG's are important is because they determine the syntax that is
possible in the language.  Simple languages might be built on what is called an LL grammar that can be parsed by what
are called recursive descent parsers.  These are simple enough that you can hand craft the parsers yourself.  But more
complex syntax requires different CFGs like LALR in which specialized tools take in special grammar rules (like Enhanced
Backus-Naur Format) in order to generate a program which in turn can build an Abstract Syntax Tree for you.

Mojo is a little unusual, in that instead of generating an Abstract Syntax Tree, it parses down to an MLIR dialect IR. I
am still learning about MLIR, but what I do know is that it is a compiler framework to help makers of hardware quickly
write compilers.  Having a compiler framework is important in the AI and High Performance Computing (HPC) worlds,
because there are many different exotic hardware types, including GPUs, TPUs, NPUs, or even quantum computers. All of
these manufacturers have their own machine code, so they also need a language _toolchain_ to do many of the same kinds
of steps that your normal CPU has to go through.

### Intermediate Representations

At the end of the compilation, we are left with what is known as an Intermediate Representation (IR).  This is a slight
abuse of terms depending on the language you are using.  For example, at the end of the C/C++ compilation step, assembly
is generated.  However, assembly can be thought of as an intermediate step on the way to the actual machine code and
thus a kind of IR.

Another well known example of an IR is Java bytecode.  Both assembly and java bytecode are lower level representations
that are midway between the source we write, and what the CPU (or other hardware accelerator) actually executes.  To put
it another way, the process of building binaries goes in steps from human readable source, to one or more IR, to the
final machine code.  Even the Java Virtual Machine eventually has to spit out machine code with the JIT compiler.

One of the reasons that MLIR was invented was because its predecessor, LLVM, could only really generate a single form of
IR (the LLVM IR).  But as it turned out, languages along the way started building their own forms of IR, because
programming language had different use cases or priorities, and they needed something more flexible before spitting out
the final machine code.  Thus, MLIR was born, which enabled language designers to create their own IRs more easily.

[Show the white paper graph with the different IRs each language developed]

One may ask why we even need IR?  Why not just go from the source code, or at least the AST, directly to the machine
code?  One of the answers to this question is optimization of code.  It is easier to do optimizations on the IR rather
than through the AST. Most modern compilers have various optimization levels that can be set that will help improve the
performance of your code.  Everything from eliminating unused code to replacing tail recursive functions with while
loops (and later in the series of articles, you will learn why a while loop is faster than a recursive function, even if
you know that the recursion will never blow the stack). 

In mojo, one can directly write in an MLIR dialect.  This is somewhat equivalent to the C or Rust worlds where you can
pass assembly directly, but mojo is more powerful.  Why?  Because when you write assembly, you are writing assembly code
for a specific hardware architecture.  Once you drop to assembly in C or rust, you have pinned your source code to a
specific CPU type.  This forces you to write `#IFDEF` preprocessor blocks in C or `#cfg[target=?]` code in rust, and
knowing the specific assembly for each CPU type.  With mojo's MLIR dialect, it's not (yet) architecture dependent. So
that's a second advantage of having multiple kinds of IR generation.

[TODO: put in code example of mlir in mojo]

One of the key takeaways of this article is to make engineers aware that code gets "lowered down" in several steps; from
the human readable source code, to IR, and finally to machine code the hardware actually executes.

### Machine Instructions

The next step in our journey is to take the IR, and convert it into the machine code that actually executes on the
hardware whether that is a CPU, GPU, NPU, or some other exotic processor.  The machine code is the infamous 1's and 0's
that gets bandied about.

One thing that many programmers never truly think about, is that at its most basic level, all data really is just 0's 
and 1's.  Whether you have a String type, a float32, or a custom data type, the system sees it has a long chain of 0's
and 1's.  Once you understand this, the next questions should be:

- where does one data value end, and another begin?
- how does a long sequence of 0's and 1's get converted into (say for example) a String?
- where do these 0's and 1's live?
- since computations are instructions + data, are instructions just sequences of 0's and 1's too?

Keep all these questions in mind, because they will be answered over time.

One thing to keep in mind is that depending on your language, in this step, you may generate more than just a single
binary.  Languages like C and Rust have a concept of a "compilation unit" (or translation unit in the C world), and is
essentially a group of one or more files that gets processed at a time.  In C, the code unit is a .c file which has also
had header files inserted or any macros/preprocessor directives expanded and an object file created from this.  In rust,
the same concept applies, and if a .rs file has any `mod` declarations, the file containing the mod is inserted into the
.rs file to be compiled as a while to generate a crate.

This then begs the question: if my code has many compilation units, from say external or internal libraries, and each
compilation unit generates it's own binary, how does the binary generated from one compilation unit's binary access code
from another compilation unit's binary?

[insert pic here of compilation unit to a binary]

That is what linking is all about.  

### Linking

The machine code that got generated in one binary unit may have symbols (and machine code implementation) in a separate
binary.  We therefore need a way to combine these binaries so that references to these symbols that exist in the
different binaries can make use of each other.  There are two general ways to do this: static and dynamic linking.

In rust and go, they have mostly opted for a static linking world.  This makes things easier, because it brings all the
needed code with it in a single binary.  All the libraries (internal or external) get linked and combined into a single
binary that is easily distributed.  This has (at least) two costs however.  It takes longer to compile, and results in a
larger binary.  It also means that if there is a bug in any compilation unit (say for example in rust, in a 3rd party
crate), then you are forced to grab the fixed version and recompile your entire code.  In a dynamic linking world, the
binary relies on external libraries such as .so files in linux or .dll in windows, that get linked at runtime.  There is
a small performance cost for this, but perhaps the bigger drawback is that it now requires the shared library to exist
in a well known location (eg /usr/lib64) and in a version compatible manner with the main binary.  This leads to what is
known as DLL hell (for dynamically linked library).  One advantage however is that it can result in much faster compile
times and smaller binaries since it does not need to self-contain any other libraries.

The process of finding the symbols in a compilation unit that are defined in a separate compilation unit is called
linking.  Rust for example uses the LLVM's lld tool to do this process as does clang if you compile with it instead of
(for example) the gnu gcc compiler.  In some cases, the OS'es system linker such as ld in linux needs to be invoked
when the external library is for example the OS'es libc.

Linking can take a long time; in some cases, it may take longer than compilation and code generation!  But the end result
is that after linking happens, we now have a program that can actually be executed, and the code in the program knows
how to find all the instructions and data it needs as it executes.

### Loading and executing

At this point, we have a functional program.  But have you ever wondered exactly how your program gets executed?  How
does it actually become a process, and how does the machine code execute instructions and load data that it needs as it
runs?

In order to understand how it works, we first need to step back a little and understand how the computer views memory, 
because fundamentally, we have to load our binary program into memory.



#### C Standard Library

All languages at some point or another, must eventually make use of the Operating System's low level resources.  For
example, opening a file requires making a System Call.  A System Call is a set of functions at the OS level that require
kernel privilege access, often to some hardware resource.  On linux, if you use the utility `strace`, you can see all
the system calls being made.  To make system calls easier, the operating system has a C standard library that are easier
wrappers around the various system calls.  It is written in C, because all major OS'es are currently written in C,
(although the linux kernel is starting to get some Rust code, as is the MS windows kernel).  It should be noted that
in the linux world, there are several possible implementations of the C standard library.  The most common is libc, aka
glibc, but musl is also sometimes seen.  This is important because

I bring this up, because you can think of the C standard library as being a part of the OS itself.  That in turn means
that things like reading and writing files or sockets requires the use of a library to do this.  In rust for example, 
there is the `std` crate which supplies the "batteries" for rust programming.  If you ever take a deep dive into the
std crate, you will see that it eventually 
