# InstanceDispatch

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://klafyvel.github.io/InstanceDispatch.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://klafyvel.github.io/InstanceDispatch.jl/dev/)
[![Build Status](https://github.com/klafyvel/InstanceDispatch.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/klafyvel/InstanceDispatch.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/klafyvel/InstanceDispatch.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/klafyvel/InstanceDispatch.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

InstanceDispatch.jl is a single-macro package to mix enumerations (or anything that defines a method for `Base.instances`) and dispatch-on-value in Julia. 

Simply put it allows using dispatching in a type-stable fashion by writing code such as:

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

## Installation

```julia
import Pkg; Pkg.add("InstanceDispatch")
```

## Alternatives

* [ValSplit.jl](https://github.com/ztangent/ValSplit.jl) essentially performs the same task for `Symbol`-based value type dispatch.
