# Zig itertools

This is an attempt to port the itertools library from python to zig, in order to introduce a functional
paradigm to the language. Maintains efficiency by reducing temporary allocations, and moving through 
slices using an iterator. The library also includes some constructs such as map, filter and reduce which 
are part of the python builtin library which are essential for functional programming.

And of course, their compile time counterparts!

Suggestions and contributions are welcome.

## Generic Iterator

## Reduce

## Map

## Filter

## Accumulate

## Dropwhile

## Filterfalse


Note: The library does not support generators yet