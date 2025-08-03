using Test
using Aqua
using InstanceDispatch
import Pkg

Pkg.add("JET")
using JET

module InstanceDispatchTest
    using InstanceDispatch
    @enum GreetEnum Hello Goodbye
end

@testset "InstanceDispatch.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(InstanceDispatch)
    end

    @testset "Code linting (JET.jl)" begin
        JET.test_package(InstanceDispatch; target_defined_modules = true)
    end

    @testset "@instancedispatch macro" begin
        @testset "Basic usage." begin
            InstanceDispatchTest.eval(
                quote
                    function greet(::Val{Hello}, who)
                        return "Hello " * who
                    end
                    function greet(::Val{Goodbye}, who)
                        return "Goodbye " * who
                    end
                    @instancedispatch greet(::GreetEnum, who)
                end
            )
            @test length(methods(InstanceDispatchTest.greet)) == 3
            @test InstanceDispatchTest.greet(InstanceDispatchTest.Hello, "me") == "Hello me"
            @test InstanceDispatchTest.greet(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
            @test_opt InstanceDispatchTest.greet(InstanceDispatchTest.Hello, "me")
        end

        @testset "Named enum parameter" begin
            InstanceDispatchTest.eval(
                quote
                    function greet1(::Val{Hello}, who)
                        return "Hello " * who
                    end
                    function greet1(::Val{Goodbye}, who)
                        return "Goodbye " * who
                    end
                    @instancedispatch greet1(enum::GreetEnum, who)
                end
            )
            @test length(methods(InstanceDispatchTest.greet1)) == 3
            @test InstanceDispatchTest.greet1(InstanceDispatchTest.Hello, "me") == "Hello me"
            @test InstanceDispatchTest.greet1(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
        end

        @testset "Keyword parameter" begin
            InstanceDispatchTest.eval(
                quote
                    function greet2(::Val{Hello}, who; punctuation)
                        return "Hello " * who * punctuation
                    end
                    function greet2(::Val{Goodbye}, who; punctuation)
                        return "Goodbye " * who * punctuation
                    end
                    @instancedispatch greet2(e::GreetEnum, args...; kwargs...)
                end
            )
            @test length(methods(InstanceDispatchTest.greet2)) == 3
            @test InstanceDispatchTest.greet2(InstanceDispatchTest.Hello, "me", punctuation = ".") == "Hello me."
            @test InstanceDispatchTest.greet2(InstanceDispatchTest.Goodbye, "me", punctuation = ".") == "Goodbye me."
        end

        @testset "Default values" begin
            InstanceDispatchTest.eval(
                quote
                    function greet3(::Val{Hello}, who)
                        return "Hello " * who
                    end
                    function greet3(::Val{Goodbye}, who)
                        return "Goodbye " * who
                    end
                    @instancedispatch greet3(::GreetEnum = Hello, who = "World!")
                end
            )
            @test length(methods(InstanceDispatchTest.greet3)) == 5
            @test InstanceDispatchTest.greet3() == "Hello World!"
            @test InstanceDispatchTest.greet3(InstanceDispatchTest.Hello, "me") == "Hello me"
            @test InstanceDispatchTest.greet3(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
        end

        @testset "Type annotations" begin
            InstanceDispatchTest.eval(
                quote
                    function greet4(::Val{Hello}, who; punctuation)
                        return "Hello " * who * punctuation
                    end
                    function greet4(::Val{Goodbye}, who; punctuation)
                        return "Goodbye " * who * punctuation
                    end
                    @instancedispatch greet4(e::GreetEnum, who::String; punctuation::String)
                end
            )
            @test length(methods(InstanceDispatchTest.greet4)) == 3
            @test InstanceDispatchTest.greet4(InstanceDispatchTest.Hello, "me", punctuation = ".") == "Hello me."
            @test InstanceDispatchTest.greet4(InstanceDispatchTest.Goodbye, "me", punctuation = ".") == "Goodbye me."
        end

        @testset "Default values in kwargs" begin
            InstanceDispatchTest.eval(
                quote
                    function greet5(::Val{Hello}, who; punctuation)
                        return "Hello " * who * punctuation
                    end
                    function greet5(::Val{Goodbye}, who; punctuation)
                        return "Goodbye " * who * punctuation
                    end
                    @instancedispatch greet5(e::GreetEnum, who; punctuation::String = ".")
                end
            )
            @test length(methods(InstanceDispatchTest.greet5)) == 3
            @test InstanceDispatchTest.greet5(InstanceDispatchTest.Hello, "me") == "Hello me."
            @test InstanceDispatchTest.greet5(InstanceDispatchTest.Hello, "me", punctuation = "!") == "Hello me!"
            @test InstanceDispatchTest.greet5(InstanceDispatchTest.Goodbye, "me", punctuation = "!") == "Goodbye me!"
        end

        @testset "Where clause" begin
            InstanceDispatchTest.eval(
                quote
                    function greet6(::Val{Hello}, who)
                        return "Hello " * who
                    end
                    function greet6(::Val{Goodbye}, who)
                        return "Goodbye " * who
                    end
                    @instancedispatch greet6(e::GreetEnum, who::T) where {T <: AbstractString}
                end
            )
            @test length(methods(InstanceDispatchTest.greet6)) == 3
            @test InstanceDispatchTest.greet6(InstanceDispatchTest.Hello, "me") == "Hello me"
            @test InstanceDispatchTest.greet6(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
        end

        @testset "Unnamed arguments" begin
            InstanceDispatchTest.eval(
                quote
                    function greet7(::Val{Hello}, who)
                        return "Hello " * who
                    end
                    function greet7(::Val{Goodbye}, who)
                        return "Goodbye " * who
                    end
                    @instancedispatch greet7(e::GreetEnum, ::String)
                end
            )
            @test length(methods(InstanceDispatchTest.greet7)) == 3
            @test InstanceDispatchTest.greet7(InstanceDispatchTest.Hello, "me") == "Hello me"
            @test InstanceDispatchTest.greet7(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
        end

        @testset "Val parameters prior to enum" begin
            InstanceDispatchTest.eval(
                quote
                    @enum TitleEnum Citizen Comrade
                    title(::Val{Citizen}) = "citizen"
                    title(::Val{Comrade}) = "comrade"
                    function greet8(::Val{Hello}, t::Val, who)
                        return join(["Hello", title(t), who], " ")
                    end
                    function greet8(::Val{Goodbye}, t::Val, who)
                        return join(["Goodbye", title(t), who], " ")
                    end
                    @instancedispatch greet8(::GreetEnum, t::TitleEnum, who)
                    @instancedispatch greet8(::Val, t::TitleEnum, who)
                end
            )
            @test length(methods(InstanceDispatchTest.greet8)) == 4
            @test InstanceDispatchTest.greet8(InstanceDispatchTest.Hello, InstanceDispatchTest.Citizen, "me") == "Hello citizen me"
            @test InstanceDispatchTest.greet8(InstanceDispatchTest.Goodbye, InstanceDispatchTest.Comrade, "me") == "Goodbye comrade me"
        end

        @testset "Dotted function names" begin
            InstanceDispatchTest.eval(
                quote
                    Base.:*(::Val{Hello}, n) = "Hello " * n
                    Base.:*(::Val{Goodbye}, n) = "Goodbye " * n
                    @instancedispatch (Base.:*)(::GreetEnum, n)
                end
            )
            @test hasmethod(Base.:*, Tuple{InstanceDispatchTest.GreetEnum, Any})
            @test InstanceDispatchTest.Hello * "me" == "Hello me"
            @test InstanceDispatchTest.Goodbye * "me" == "Goodbye me"
        end

        @testset "Inadequate expressions" begin
            # not a function call
            @test_throws LoadError InstanceDispatchTest.eval(:(@instancedispatch greet(e::GreetEnum, who) = println(e, who)))
            !
            # Not enough arguments
            @test_throws LoadError InstanceDispatchTest.eval(:(@instancedispatch greet()))
            # Wrong type argument for the enum
            @test_throws MethodError InstanceDispatchTest.eval(:(@instancedispatch greet(e)))
            # Slurping is not supported
            @test_throws LoadError InstanceDispatchTest.eval(:(@instancedispatch greet(e::GreetEnum...)))
            # The ONLY requirement of the package is to have a `Base.instances` method!
            @test_throws MethodError InstanceDispatchTest.eval(:(@instancedispatch greet(e::Int)))

        end
    end
end
