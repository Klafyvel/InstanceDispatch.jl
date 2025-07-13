module InstanceDispatch

function getargumentname(arg)
    if arg isa Symbol
        return String(arg)
    elseif arg.head == :...
        v = only(arg.args)
        return String(v)
    elseif arg.head == :(::)
        if length(arg.args) > 1
            v = first(arg.args)
            return String(v)
        else
            # FIXME: This argument is ignored and just used for dispatching for now,
            # is it better to pass it to the callee instead?
        end
    else # Need to clean the default value
        argname = first(arg.args)
        if argname isa Symbol
            return String(argname)
        elseif length(argname.args) > 1
            v = first(argname.args)
            return String(v)
        else
            # FIXME: This argument is ignored and just used for dispatching for now,
            # is it better to pass it to the callee instead?
        end
    end
end
function getargumentcallee(arg)
    name = getargumentname(arg)
    if isnothing(name)
        return nothing
    end
    if (arg isa Symbol) || arg.head ≠ :...
        return Expr(:call, :Symbol, name)
    else
        return Expr(:call, Expr, Expr(:call, Symbol, "..."), Expr(:call, :Symbol, name))
    end
end
function getargumentdef(arg)
    if arg isa Symbol
        return Expr(:call, :Symbol, getargumentname(arg))
    elseif arg.head == :...
        return Expr(:call, Expr, Expr(:call, :Symbol, "..."), Expr(:call, :Symbol, getargumentname(arg)))
    elseif arg.head == :(::)
        if length(arg.args) > 1
            return Expr(:call, :Expr, Expr(:call, Symbol, "::"), Expr(:call, :Symbol, getargumentname(first(arg.args))), last(arg.args))
        else
            return arg
        end
    elseif arg.head == :parameters
        kwargs = [getargumentdef(kwarg) for kwarg in arg.args]
        return Expr(:call, :Expr, Expr(:call, :Symbol, "parameters"), kwargs...)
    else # Need to clean the default value
        argname = first(arg.args)
        if argname isa Symbol || length(argname.args) > 1
            return Expr(:call, Expr, Expr(:call, :Symbol, "kw"), getargumentdef(argname), last(arg.args))
        else
            return arg
        end
    end
end


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
    else
    end
end
```
"""
macro instancedispatch(fcall)
    if fcall.head ≠ :call
        throw(ArgumentError("@instancedispatch must be called on a function call. Example: `@instancedispatch foo(::MyEnum)`."))
    end
    if length(fcall.args) < 2
        throw(ArgumentError("@instancedispatch expects at least one argument to the call: the enumeration type. Example: `@instancedispatch foo(::MyEnum)`."))
    end
    fname = Expr(:call, :Symbol, first(fcall.args))
    enumtype = nothing
    arguments = []
    callee_arguments = []
    callee_kwarguments = []
    isenumdef = true
    for arg in fcall.args[2:end]
        defarg = arg
        callarg = arg
        if isenumdef && arg isa Symbol
            throw(ArgumentError("The first argument to the call in `@instancedispatch` must specify an enum type. Example: `@instancedispatch foo(::MyEnum)`."))
        elseif isenumdef && arg.head != :parameters # This is the enum declaration!
            enumdefault = nothing
            if arg.head == :(::) # This is something in the form `foo(e::MyEnum)`.
                enumtype = last(arg.args)
            else # This is something in the form `foo(e::MyEnum=Foo)`.
                typedef = first(arg.args)
                enumdefault = last(arg.args)
                enumtype = last(typedef.args)
            end
            defarg = Expr(:(::), :e, enumtype)
            if !isnothing(enumdefault)
                defarg = Expr(:kw, defarg, enumdefault)
            end
        end
        push!(arguments, getargumentdef(defarg))
        if isenumdef && arg.head != :parameters
            isenumdef = false
        elseif arg isa Symbol || arg.head != :parameters
            argcallee = getargumentcallee(arg)
            if !isnothing(argcallee)
                push!(callee_arguments, argcallee)
            end
        else
            for kwarg in callarg.args
                argcallee = getargumentcallee(kwarg)
                if !isnothing(argcallee)
                    push!(callee_kwarguments, argcallee)
                end
            end
        end
    end
    return Expr(
        :escape, quote
            eval(
                let
                    ifelseblock = foldr(instances($enumtype), init = :()) do instance, r
                        Expr(
                            :elseif,
                            Expr(:call, :(==), :e, Symbol(instance)),
                            Expr(
                                :return,
                                Expr(
                                    :call, $fname,
                                    Expr(:parameters, $(callee_kwarguments...)),
                                    Expr(:call, :Val, Symbol(instance)),
                                    $(callee_arguments...)
                                )
                            ),
                            r
                        )
                    end
                    ifelseblock.head = :if
                    Expr(:function, Expr(:call, $fname, $(arguments...)), ifelseblock)
                end
            )
        end
    )
end

export @instancedispatch

end
