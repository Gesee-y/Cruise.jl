#####################################################################################################################################
####################################################### Minimal Observer Pattern ####################################################
#####################################################################################################################################

export CRSubject, connect, disconnect, notify!

const Observer = Function

mutable struct CRSubject{T}
    value::T
    observers::Vector{Observer}

    CRSubject(value::T) where T = new{T}(value, Observer[])
end

function connect(f::Observer, s::CRSubject)
    push!(s.observers, f)
    return f
end

function disconnect(s::CRSubject, f::Observer)
    idx = findfirst(==(f), s.observers)
    idx !== nothing && deleteat!(s.observers, idx)
end

function notify!(s::CRSubject)
    for obs in s.observers
        args = isnothing(s.value) ? () : (s.value,)
        obs(args...)
    end
end

Base.getindex(s::CRSubject) = s.value
Base.setindex!(s::CRSubject, v) = (s.value = v)
