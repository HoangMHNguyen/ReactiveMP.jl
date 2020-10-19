module RocketTest

using Test, Documenter, Rocket

# doctest(Rocket)

@testset "ReactiveMP" begin

    include("test_distributions.jl")
    include("distributions/test_normal_mean_variance.jl")
    include("distributions/test_normal_mean_precision.jl")

    @testset "Detect ambiguities" begin
        @test length(Test.detect_ambiguities(Rocket)) == 0
    end
end

end