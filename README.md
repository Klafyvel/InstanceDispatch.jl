# InstanceDispatch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://klafyvel.github.io/InstanceDispatch.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://klafyvel.github.io/InstanceDispatch.jl/dev/)
[![Build Status](https://github.com/klafyvel/InstanceDispatch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/klafyvel/InstanceDispatch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/klafyvel/InstanceDispatch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/klafyvel/InstanceDispatch.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A single macro package to mix enumerations (or anything that defines a method for `Base.instances`) and dispatch-on-value in Julia.

## Example

```julia
using InstanceDispatch

@enum GreetEnum Hello Goodbye

function greet(::Val{Hello}, who)
    return "Hello " * who
end
function greet(::Val{Goodbye}, who)
    return "Goodbye " * who
end
@instancedispatch greet(::GreetEnum, who)
```

This last line is equivalent to defining the following method:
```julia
function greet(e::GreetEnum, who)
    if e == Hello
        return greet(Val(Hello), who)
    elseif e == Goodbye
        return greet(Val(Goodbye), who)
    else
    end
end
```

This avoids [the performance pit](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-value-type) that you would encounter in simply writing:
```julia
function greet(e::GreetEnum, who)
    return greet(Val(e), who)
end
```

The `@instancedispatch` macro will do its best to reproduce the arguments of the function call you pass to it. This gives you some leverage to use julia's dispatch
```julia-repl
julia> using InstanceDispatch
Precompiling InstanceDispatch...
  1 dependency successfully precompiled in 1 seconds

julia> @enum GreetEnum Hello Goodbye

julia> function greet(::Val{Hello}, who)
           return "Hello " * who
       end
greet (generic function with 1 method)

julia> function greet(::Val{Goodbye}, who)
           return "Goodbye " * who
       end
greet (generic function with 2 methods)

julia> function greet(::Val{Hello}, n::Int)
       return "Hello" ^ n
       end
greet (generic function with 3 methods)

julia> @instancedispatch greet(::GreetEnum, who::String)
greet (generic function with 4 methods)

julia> function greet(::Val{Goodbye}, n::Int)
       return "Goodbye" ^ n
       end
greet (generic function with 5 methods)

julia> @instancedispatch greet(::GreetEnum, who::Int)
greet (generic function with 6 methods)

julia> greet(Hello, "me")
"Hello me"

julia> greet(Hello, 5)
"HelloHelloHelloHelloHello"
```

## Installation

```julia
import Pkg; Pkg.add("InstanceDispatch")
```
