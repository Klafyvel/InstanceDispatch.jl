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
"""
macro instancedispatch(fcall)
    has_where_call = @capture(fcall, newfcall_ where {T__})
    if has_where_call
        fcall = newfcall
    end
    @capture(fcall, fname_(args__; kwargs__) | fname_(args__)) || throw(ArgumentError("@instancedispatch must be called on a function call. Example: `@instancedispatch foo(::MyEnum)`. Got $(prettify(fcall))"))
    original_arguments = splitarg.(args)
    length(original_arguments) ≥ 1 || throw(ArgumentError("@instancedispatch expects at least one argument to the call: the enumeration type. Example: `@instancedispatch foo(::MyEnum)`. Got $(args)."))
    fname_expr = exex(fname)
    enum_argument_name = :e
    enum_type = :Any
    definition_arguments = []
    callee_arguments = []
    isenumdef = true
    for arg in original_arguments
        arg_name, arg_type, slurp, default = arg
        if !isenumdef
            push!(definition_arguments, arg)
            isnothing(arg_name) || push!(callee_arguments, arg)
        else
            isenumdef = false
            enum_argument_name = something(arg_name, enum_argument_name)
            (arg_type isa Symbol) || throw(ArgumentError("The dispatched type must be a known type, not $(prettify(arg_type))."))
            enum_type = arg_type
            slurp && throw(ArgumentError("The dispatched argument cannot be a slurp!"))
            push!(definition_arguments, (enum_argument_name, arg_type, false, default))
        end
    end
    definition_arguments = map(exex ∘ splat(combinearg), definition_arguments)
    isnothing(kwargs) || pushfirst!(definition_arguments, exex(Expr(:parameters, kwargs...)))
    enum_argument_name = exex(enum_argument_name)
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
