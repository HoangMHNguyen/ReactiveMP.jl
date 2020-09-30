export skipindex, @symmetrical

using SpecialFunctions
using Rocket

import Base: show
import Base: IteratorSize, HasLength
import Base: IteratorEltype, HasEltype
import Base: eltype, length, size
import Base: IndexStyle, IndexLinear, getindex

struct SkipIndexIterator{T, I} <: AbstractVector{T}
    iterator :: I
    skip     :: Int
end

skip(iter::SkipIndexIterator) = iter.skip

function skipindex(iterator::I, skip::Int) where I
    @assert skip >= 1
    @assert length(iterator) >= 1
    return SkipIndexIterator{eltype(I), I}(iterator, skip)
end

Base.IteratorSize(::Type{<:SkipIndexIterator})   = HasLength()
Base.IteratorEltype(::Type{<:SkipIndexIterator}) = HasEltype()
Base.IndexStyle(::Type{<:SkipIndexIterator})     = IndexLinear()

Base.eltype(::Type{<:SkipIndexIterator{T}}) where T = T
Base.length(iter::SkipIndexIterator)                = length(iter.iterator) - 1
Base.size(iter::SkipIndexIterator)                  = (length(iter), )

Base.getindex(iter::SkipIndexIterator, i) = i < skip(iter) ? @inbounds(iter.iterator[i]) : @inbounds(iter.iterator[i + 1])

"""
    @symmetrical `function_definition`
Duplicate a method definition with the order of the first two arguments swapped.
This macro is used to duplicate methods that are symmetrical in their first two input arguments,
but require explicit definitions for the different argument orders.
Example:
    @symmetrical function prod!(x, y, z)
        ...
    end
"""
macro symmetrical(fn::Expr)
    # Check if macro is applied to a function definition
    # Valid function definitions include:
    # 1. foo([ args... ]) [ where ... [ where ... [ ... ] ] ] = :block
    # 2. function foo([ args... ]) [ where ... [ where ... [ ... ] ] ]
    #        :block
    #    end
    if (fn.head === :(=) || fn.head === :function) &&
        (fn.args[1] isa Expr && fn.args[2] isa Expr) &&
        (fn.args[2].head === :block)
        return esc(quote
            $fn
            $(swap_arguments(fn))
        end)
    else
        error("@symmetrical macro can be applied only to function definitions")
    end
end

function swap_arguments(fn::Expr)
    swapped = copy(fn)

    if swapped.args[1].head === :where
        swapped.args[1] = swap_arguments(swapped.args[1])
    elseif swapped.args[1].head === :call && length(fn.args[1].args) >= 3 # Note: >= 3, because the first argument is a function name
        swapped.args[1].args[2] = fn.args[1].args[3]
        swapped.args[1].args[3] = fn.args[1].args[2]
    else
        error("Function method passed for @symmetrical macro must have more than 2 arguments")
    end

    return swapped
end

function labsgamma(x::Number)
    return SpecialFunctions.logabsgamma(x)[1]
end

cast_to_subscribable(some::T) where T = cast_to_subscribable(as_subscribable(T), some)

cast_to_subscribable(::InvalidSubscribableTrait, some)   = of(some)
cast_to_subscribable(::SimpleSubscribableTrait, some)    = some
cast_to_subscribable(::ScheduledSubscribableTrait, some) = some

reduce_with_sum(array) = reduce(+, array)

## 

import Base: +, -, *, /, convert, float, isfinite, isinf

struct Infinity 
    degree :: Int
end

degree(a::Infinity) = a.degree

const ∞ = Infinity(1)

Base.:+(a::Infinity, b::Infinity) = Infinity(degree(a) + degree(b))
Base.:-(a::Infinity, b::Infinity) = Infinity(degree(a) - degree(b))
Base.:*(a::Infinity, b::Infinity) = Infinity(degree(a) * degree(b))
Base.:/(a::Infinity, b::Infinity) = error("Its not possible to divide Infinities")

@symmetrical Base.:*(a::Infinity, b::Int) = Infinity(degree(a) * b)

struct InfCountingReal{ T <: Real } <: Real
    value :: T
    infs  :: Int
end

InfCountingReal(value::T) where { T <: Real } = InfCountingReal{T}(value, 0)

value(a::InfCountingReal) = a.value
infs(a::InfCountingReal)  = a.infs

isfinite(a::InfCountingReal) = infs(a) === 0
isinf(a::InfCountingReal)    = !(isfinite(a))

@symmetrical Base.:+(a::InfCountingReal{T}, b::Infinity) where T = InfCountingReal{T}(value(a), infs(a) + degree(b))
@symmetrical Base.:-(a::InfCountingReal{T}, b::Infinity) where T = InfCountingReal{T}(value(a), infs(a) - degree(b))
@symmetrical Base.:*(::InfCountingReal, ::Infinity) = error("Its not possible to multiply on Infinity")
@symmetrical Base.:/(::InfCountingReal, ::Infinity) = error("Its not possible to divide by Infinity")

@symmetrical Base.:+(a::InfCountingReal{T}, b::Real) where T = InfCountingReal{T}(convert(T, value(a) + b), infs(a))
@symmetrical Base.:-(a::InfCountingReal{T}, b::Real) where T = InfCountingReal{T}(convert(T, value(a) - b), infs(a))
@symmetrical Base.:*(a::InfCountingReal{T}, b::Real) where T = InfCountingReal{T}(convert(T, value(a) * b), infs(a))
@symmetrical Base.:/(a::InfCountingReal{T}, b::Real) where T = InfCountingReal{T}(convert(T, value(a) / b), infs(a))

Base.convert(::Type{T}, a::InfCountingReal) where { T <: Real } = isfinite(a) ? convert(T, value(a)) : Inf

Base.float(a::InfCountingReal) = convert(Float64, a)

Base.show(io::IO, a::InfCountingReal) = print(io, "InfCountingReal($(value(a)), $(infs(a)))")


