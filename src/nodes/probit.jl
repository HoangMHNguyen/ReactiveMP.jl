using StatsFuns: normcdf

export Probit, ProbitMeta

struct Probit end

struct ProbitMeta
    p :: Int
end

getp(meta::ProbitMeta) = meta.p

ProbitMeta(; p = 32) = ProbitMeta(p)

@node Probit Stochastic [ out, in ]

default_meta(::Type{ Probit }) = ProbitMeta(32)

default_functional_dependencies_pipeline(::Type{ <: Probit }) = RequireInboundFunctionalDependencies((2, ), (vague(NormalMeanPrecision), ))

default_interface_local_constraint(::Type{ <: Probit }, edge::Val{ :in })  = MomentMatching()
default_interface_local_constraint(::Type{ <: Probit }, edge::Val{ :out }) = Marginalisation()

@average_energy Probit (q_out::Union{PointMass, Bernoulli}, q_in::UnivariateNormalDistributionsFamily, meta::ProbitMeta) = begin

    # extract parameters
    p = mean(q_out)
    m, v = mean_var(q_in)

    # specify function
    h = (x) -> -p*log(normcdf(x)) - (1-p)*log(normcdf(-x))

    # calculate average average energy (default of 32 points)
    gh_cubature = GaussHermiteCubature(getp(meta))
    U = 0.0
    tmp = sqrt(2*v)
    for k = 1:getp(meta)
        U += gh_cubature.witer[k] * h( gh_cubature.piter[k] * tmp + m)
    end
    U /= sqrt(pi)
    
    # return average energy
    return U

end