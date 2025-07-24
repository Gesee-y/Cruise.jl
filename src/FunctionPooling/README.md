## FunctionPooling: Efficient functions recycling

Julia is a powerful language. From metaprogrammation to multiple dispatch, this language offer incredible tool to make work easier while making the most serious devs happy. However, it still suffer from serious issue: **memory leaks**.

When you create new function's definition, julia store them in a `MethodTable` and with his JIT, will compile them once you will use them. But now here is the problem. Once a function is compiled, Julia has no way to know if the function is unused so it's never collected by the garbage collector. 
For a programm that dynamically create function, we end up slowly leaking memory until the program crash.

So this package comes with a solution. **Recycling functions**.
Instead of creating new methods or new function, we will **override** the old ones and replace them with our new function. This drastically reduce the amount of memory leaked as tested for 1000 functions:

```
# Standard way
Memory in use: 55.5 Mo

# With recycled functions
Memory in use: 9.9 Mo
```

## Installation

For now, this package is only used by my game engine [Cruise](https://github.com/Gesee-y/Cruise.jl)

```
julia> ]add https://github.com/Gesee-y/Cruise.jl/main/blob/src/FunctionPooling
```

## Features

- `FunctionPool()`: A new instance to manage a pool of functions.
- `@pooledfunction pool function name() ... end`: A new function that will automatically override unsused functions
- `FunctionObject`: An instance of a recyclabe function.
- `free`: Mark a given function object as reusable and can be recycled at any time.
- `getname`: The named of the function that is overriden in a `FunctionObject`.
- `getfunc`: The actual function getting overriden in a `FunctionObject`.

## Other Insight

For better results you cans also use `functor`s to if only the internal data of your function change. Or you can use DynamicExpression.jl if performances aren't a bottle neck.

## Bug report

If you notice any bug or inconsistencies in this package, feel free to raise an issue.
