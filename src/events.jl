##############################
# Minimal Observer Pattern
##############################

const Observer = Function

mutable struct CRSubject{T}
    value::T
    observers::Vector{Observer}

    Subject(value::T) where T = new{T}(value, Observer[])
end

function subscribe!(s::Subject, f::Observer)
    push!(s.observers, f)
    return f
end

function unsubscribe!(s::Subject, f::Observer)
    idx = findfirst(==(f), s.observers)
    idx !== nothing && deleteat!(s.observers, idx)
end

function notify!(s::Subject)
    for obs in s.observers
        obs(s.value)
    end
end

Base.getindex(s::Subject) = s.value
Base.setindex(s::Subject, v) = (s.value = v)
