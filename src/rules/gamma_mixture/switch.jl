
@rule GammaMixture{N}(:switch, Marginalisation) (q_out::Any, q_a::NTuple{N, GammaDistributionsFamily }, q_b::NTuple{N, GammaDistributionsFamily }) where { N } = begin
    # p. 12
    # TODO: Needs further discussion, doublecheck
    ρ =  map(1:N) do k
        x = labsgamma(q_b[k]) * mean(q_a[k])
        y = labsgamma(q_out) * (mean(q_a[k]) - 1)
        z = labsgamma(q_out) * mean(q_a[k])
        d = mean(q_b[k]) * mean(q_out)
        return exp(x + y - z - d)
    end

    ρ = clamp.(ρ, tiny, 1.0 - tiny)

    return Categorical(ρ ./ sum(ρ))
end
