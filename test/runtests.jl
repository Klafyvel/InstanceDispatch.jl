using Test
using Aqua
using JET
using InstanceDispatch

module InstanceDispatchTest
    using InstanceDispatch
    @enum GreetEnum Hello Goodbye

    function greet(::Val{Hello}, who)
        return "Hello " * who
    end
    function greet(::Val{Goodbye}, who)
        return "Goodbye " * who
    end
    @instancedispatch greet(::GreetEnum, who)

    #alternative syntaxes
    function greet1(::Val{Hello}, who)
        return "Hello " * who
    end
    function greet1(::Val{Goodbye}, who)
        return "Goodbye " * who
    end
    @instancedispatch greet1(e::GreetEnum, who)
    
    function greet2(::Val{Hello}, who; punctuation)
        return "Hello " * who * punctuation
    end
    function greet2(::Val{Goodbye}, who; punctuation)
        return "Goodbye " * who * punctuation
    end
    @instancedispatch greet2(e::GreetEnum, args...; kwargs...)

    function greet3(::Val{Hello}, who)
        return "Hello " * who
    end
    function greet3(::Val{Goodbye}, who)
        return "Goodbye " * who
    end
    @instancedispatch greet3(::GreetEnum=Hello, who="World!")
end

@testset "InstanceDispatch.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(InstanceDispatch)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(InstanceDispatch; target_defined_modules = true)
    end
    # Write your tests here.
    @testset "@instancedispatch macro" begin
        @test length(methods(InstanceDispatchTest.greet)) == 3
        @test InstanceDispatchTest.greet(InstanceDispatchTest.Hello, "me") == "Hello me"
        @test InstanceDispatchTest.greet(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
        @test_opt InstanceDispatchTest.greet(InstanceDispatchTest.Hello, "me")

        #alternative syntaxes
        @test length(methods(InstanceDispatchTest.greet1)) == 3
        @test InstanceDispatchTest.greet1(InstanceDispatchTest.Hello, "me") == "Hello me"
        @test InstanceDispatchTest.greet1(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"

        @test length(methods(InstanceDispatchTest.greet2)) == 3
        @test InstanceDispatchTest.greet2(InstanceDispatchTest.Hello, "me", punctuation=".") == "Hello me."
        @test InstanceDispatchTest.greet2(InstanceDispatchTest.Goodbye, "me", punctuation=".") == "Goodbye me."

        @test length(methods(InstanceDispatchTest.greet3)) == 5
        @test InstanceDispatchTest.greet3() == "Hello World!"
        @test InstanceDispatchTest.greet3(InstanceDispatchTest.Hello, "me") == "Hello me"
        @test InstanceDispatchTest.greet3(InstanceDispatchTest.Goodbye, "me") == "Goodbye me"
    end
end

