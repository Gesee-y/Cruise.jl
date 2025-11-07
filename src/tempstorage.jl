export TempStorage, addvar!, getvar, hasvar, delvar!, clear!, save!, load!, cleanup!,
       on, off

using Dates, JSON

"""
    TempStorage()

A temporary storage system supporting:
- **Namespaces** (`ns`) for organizing variables  
- **Automatic expiration** (`ttl`) with cleanup  
- **Event system** for reacting to changes (`:add`, `:delete`, `:expire`)
"""
mutable struct TempStorage
    data::Dict{String, Any}
    expirations::Dict{String, DateTime}
    listeners::Dict{Symbol, Vector{Function}}
end

TempStorage() = TempStorage(Dict{String, Any}(), Dict{String, DateTime}(), Dict{Symbol, Vector{Function}}())

# -- Utilities ------------------------------------------------------

_fullname(ns::Union{Nothing, String}, name::String) = ns === nothing ? name : "$ns/$name"

# -- Event system ---------------------------------------------------

"""
    on(ts::TempStorage, event::Symbol, callback::Function)

Registers a callback function for an event.  
Supported events:
- `:add` — triggered when a variable is added  
- `:delete` — triggered when a variable is deleted  
- `:expire` — triggered when a variable expires  
"""
function on(ts::TempStorage, event::Symbol, callback::Function)
    v = get!(ts.listeners, event, Vector{Function}())
    push!(v, callback)
end

"""
    off(ts::TempStorage, event::Symbol, callback::Function)

Unregisters a previously registered callback for a specific event.
"""
function off(ts::TempStorage, event::Symbol, callback::Function)
    if haskey(ts.listeners, event)
        filter!(f -> f !== callback, ts.listeners[event])
    end
end

# Helper to emit events
function _emit(ts::TempStorage, event::Symbol, args...)
    if haskey(ts.listeners, event)
        for cb in ts.listeners[event]
            try
                cb(args...)
            catch e
                @warn "Event callback error" exception=(e, catch_backtrace())
            end
        end
    end
end

# -- Core API -------------------------------------------------------

"""
    addvar!(ts::TempStorage, name::String, value; ns=nothing, ttl=nothing)

Adds a variable to the storage.  
- `ns`: optional namespace  
- `ttl`: optional expiration duration (e.g. `Second(5)` or `Minute(1)`)
"""
function addvar!(ts::TempStorage, name::String, value; ns=nothing, ttl=nothing)
    key = _fullname(ns, name)
    ts.data[key] = value
    if ttl !== nothing
        ts.expirations[key] = now() + ttl
    end
    _emit(ts, :add, key, value)
    return value
end

"""
    getvar(ts::TempStorage, name::String; ns=nothing, default=nothing)

Returns the value of a variable, or `default` if it does not exist or has expired.
"""
function getvar(ts::TempStorage, name::String; ns=nothing, default=nothing)
    cleanup!(ts)
    key = _fullname(ns, name)
    return get(ts.data, key, default)
end

"""
    hasvar(ts::TempStorage, name::String; ns=nothing) -> Bool

Checks whether a variable exists and has not expired.
"""
function hasvar(ts::TempStorage, name::String; ns=nothing)
    cleanup!(ts)
    key = _fullname(ns, name)
    return haskey(ts.data, key)
end

"""
    delvar!(ts::TempStorage, name::String; ns=nothing)

Deletes a variable if it exists.
"""
function delvar!(ts::TempStorage, name::String; ns=nothing)
    key = _fullname(ns, name)
    value = pop!(ts.data, key, nothing)
    pop!(ts.expirations, key, nothing)
    if value !== nothing
        _emit(ts, :delete, key, value)
    end
end

"""
    clear!(ts::TempStorage; ns=nothing)

Clears all variables, or only those within the specified namespace.
"""
function clear!(ts::TempStorage; ns=nothing)
    if ns === nothing
        for (k, v) in collect(ts.data)
            delvar!(ts, k)
        end
    else
        prefix = "$ns/"
        for k in collect(keys(ts.data))
            startswith(k, prefix) && delvar!(ts, k)
        end
    end
end

"""
    cleanup!(ts::TempStorage)

Removes all expired variables and triggers `:expire` events.
"""
function cleanup!(ts::TempStorage)
    nowtime = now()
    expired = [k for (k, t) in ts.expirations if t < nowtime]
    for k in expired
        val = ts.data[k]
        delvar!(ts, k)
        _emit(ts, :expire, k, val)
    end
end

"""
    save!(ts::TempStorage, filepath::String)

Saves the current state to a JSON file, including expiration times.
"""
function save!(ts::TempStorage, filepath::String)
    cleanup!(ts)
    open(filepath, "w") do io
        JSON.print(io, Dict(
            "data" => ts.data,
            "expirations" => Dict(k => string(v) for (k,v) in ts.expirations)
        ))
    end
end

"""
    load!(ts::TempStorage, filepath::String)

Loads the storage state from a JSON file.
"""
function load!(ts::TempStorage, filepath::String)
    if !isfile(filepath)
        error("File not found: $filepath")
    end
    d = JSON.parsefile(filepath)
    ts.data = Dict{String, Any}(d["data"])
    ts.expirations = Dict(k => DateTime(v) for (k,v) in d["expirations"])
end