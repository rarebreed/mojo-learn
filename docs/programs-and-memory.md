# How programs use memory

I started writing this with the intention of just talking about the stack, heap, rgisters, and how low-level system
programming languages like mojo or rust need to think about memory.  While I had a familiarity with how memory works at
a low level from my old hardware days working on linux device drivers, I realized two things:  The first is that a lot
of knowledge had slipped my mind over time, and the second was that I would need to talk more than just the stack, heap
and registers.  This is doubly true for mojo which, unlike any mainstream language, treats SIMD and address spacess as
class citizens.

So this presentation will be broken down into two parts.  The first will cover how an operating system (or even bare
metal devices) segment memory and why an OS has virtual memory.  It will also contain some basic information on how a
program is actually loaded when you call it.  This will be the part that briefly talks about how programs are compiled 
and linked.  The second part will cover the aforementioned stack, heap and regissters, including details on caches, and
why memory access is so costly.  Finally, it will cover how this all fits into the notion of "pass by value)copy)" and
"pass by reference".