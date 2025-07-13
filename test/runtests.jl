using InstanceDispatch
using Test
using Aqua
using JET

@testset "InstanceDispatch.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(InstanceDispatch)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(InstanceDispatch; target_defined_modules = true)
    end
    # Write your tests here.
end
