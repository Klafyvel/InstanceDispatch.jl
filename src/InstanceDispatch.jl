module InstanceDispatch

using MacroTools
exex(s::Symbol) = Expr(:call, :Symbol, String(s))
exex(s) = s
exex(e::Expr) = Expr(:call, :Expr, exex(e.head), map(exex, e.args)...)
buildcalleearg(splitted) = ifelse(splitted[3], exex(Expr(:..., splitted[1])), exex(splitted[1]))

"""
    @instancedispatch myfunction(::T, args...; kwargs...)

Write a specialized function to dispatch on instances values of type `T`. The only
reauirement is that `Type{T}` has its own method for `Base.instances`.

You are allowed to chain dispatching, *i.e.* dispatching on multiple instancied types. This is done by having `Any` or `Val` parameter types prepending the enumeration. See examples.

## Examples
```julia
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
    else end
end
```

You can also dispatch on multiple enums. In that case, it is advised to explicitely
state the types as much as possible.

```julia
@enum TitleEnum Citizen Comrade
title(::Val{Citizen}) = "citizen"
title(::Val{Comrade}) = "comrade"
function greet(::Val{Hello}, t::Val, who)
    return join(["Hello", title(t), who], " ")
end
function greet(::Val{Goodbye}, t::Val, who)
    return join(["Goodbye", title(t), who], " ")
end
@instancedispatch greet(::GreetEnum, t::TitleEnum, who)
@instancedispatch greet(::Val, t::TitleEnum, who)
```

All the arguments in the function call given to the macro will be passed in the invocations. In case they are anonymous, new names will be created using `gensym`. `where` statements are supported.
"""
macro instancedispatch(fcall)
    has_where_call = @capture(fcall, newfcall_ where {T__})
    if has_where_call
        fcall = newfcall
    end
    @capture(fcall, fname_(args__; kwargs__) | fname_(args__)) || throw(ArgumentError("@instancedispatch must be called on a function call. Example: `@instancedispatch foo(::MyEnum)`. Got $(prettify(fcall))"))
    original_arguments = splitarg.(args)
    length(original_arguments) ≥ 1 || throw(ArgumentError("@instancedispatch expects at least one argument to the call: the enumeration type. Example: `@instancedispatch foo(::MyEnum)`. Got $(args)."))
    fname_expr = QuoteNode(fname)
    enum_argument_name = :e
    enum_type = :Any
    definition_arguments = []
    callee_arguments_pre = []
    callee_arguments = []
    isenumdef = true
    for arg in original_arguments
        arg_name, arg_type, slurp, default = arg
        if isenumdef && namify(arg_type) ∉ (:Val, :Any)
            isenumdef = false
            enum_argument_name = something(arg_name, enum_argument_name)
            (arg_type isa Symbol) || throw(ArgumentError("The dispatched type must be a known type, not $(prettify(arg_type))."))
            enum_type = arg_type
            slurp && throw(ArgumentError("The dispatched argument cannot be a slurp!"))
            push!(definition_arguments, (enum_argument_name, arg_type, false, default))
        else
            arg = (something(arg_name, gensym(arg_type)), arg_type, slurp, default)
            push!(definition_arguments, arg)
            isenumdef && push!(callee_arguments_pre, arg)
            !isenumdef && push!(callee_arguments, arg)
        end
    end
    definition_arguments = map(exex ∘ splat(combinearg), definition_arguments)
    isnothing(kwargs) || pushfirst!(definition_arguments, exex(Expr(:parameters, kwargs...)))
    enum_argument_name = exex(enum_argument_name)
    callee_arguments_pre = map(buildcalleearg, callee_arguments_pre)
    callee_arguments = map(buildcalleearg, callee_arguments)
    callee_kwarguments = map(buildcalleearg, splitarg.(something(kwargs, [])))
    fdef = if has_where_call
        types = exex.(T)
        :(Expr(:function, Expr(:where, Expr(:call, $fname_expr, $(definition_arguments...)), $(types...)), ifelseblock))
    else
        :(Expr(:function, Expr(:call, $fname_expr, $(definition_arguments...)), ifelseblock))
    end
    return Expr(
        :escape, quote
            let
                ifelseblock = foldr(instances($enum_type), init = :()) do instance, r
                    Expr(
                        :elseif, Expr(:call, :(==), $enum_argument_name, Symbol(instance)),
                        Expr(
                            :return, Expr(
                                :call, $fname_expr,
                                Expr(:parameters, $(callee_kwarguments...)),
                                $(callee_arguments_pre...),
                                Expr(:call, :Val, Symbol(instance)),
                                $(callee_arguments...)
                            )
                        ), r
                    )
                end
                ifelseblock.head = :if
                $fdef
            end |> eval
        end
    )
end

export @instancedispatch
end
