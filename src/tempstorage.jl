module TemporaryStorage

export TempStorage, addvar!, getvar, hasvar, delvar!, clear!, save!, load!, cleanup!,
       on, off, start_auto_cleanup!, stop_auto_cleanup!, listnamespaces, listvars

using Dates, JSON

abstract type AbstractNamespace end

mutable struct TempEntry{T}
    val::T
    expiration::DateTime

    ## Constructor

    TempEntry(v::T) where T = new{T}(v)
    TempEntry(v::T, ttl::DateTime) where T = new{T}(v, ttl)
end

mutable struct Namespace <: AbstractNamespace
    data::Dict{String, TempEntry}
    observers::Dict{Symbol, Vector{Function}}
    namespaces::Dict{String, Namespace}
    lock::ReentrantLock
    cleanup_task::Union{Nothing, Task}
    cleanup_active::Ref{Bool}
end

function Namespace()
    Namespace(
        Dict{String, TempEntry}(),
        Dict{Symbol, Vector{Function}}(),
        Dict{String, Namespace}(),
        ReentrantLock(),
        nothing,
        Ref(false)
    )
end

"""
    TempStorage()

A thread-safe temporary storage system supporting:
- **Namespaces** (`ns`) for organizing variables  
- **Automatic expiration** (`ttl`) with cleanup  
- **Event system** for reacting to changes (`:add`, `:delete`, `:expire`)
- **Auto-cleanup** background task
- **Persistence** via JSON serialization

# Example
```julia
ts = TempStorage()

# Add variable with expiration
addvar!(ts, "session", "user123", ns="auth", ttl=Minute(30))

# Listen to events
on(ts, :expire) do key, value
    @info "Expired: \$key"
end

# Start automatic cleanup every minute
start_auto_cleanup!(ts, Second(60))
```
"""
mutable struct TempStorage <: AbstractNamespace
    data::Dict{String, TempEntry}
    observers::Dict{Symbol, Vector{Tuple{Function, Function}}}
    namespaces::Dict{String, Namespace}
    lock::ReentrantLock
    cleanup_task::Union{Nothing, Task}
    cleanup_active::Ref{Bool}
end

function TempStorage()
    TempStorage(
        Dict{String, TempEntry}(),
        Dict{Symbol, Vector{Function}}(),
        Dict{String, Namespace}("" => Namespace()),
        ReentrantLock(),
        nothing,
        Ref(false)
    )
end

# -- Utilities ------------------------------------------------------

"""
Validates variable name (no slashes, not empty)
"""
function _validate_name(name::String)
    if isempty(name)
        throw(ArgumentError("Variable name cannot be empty"))
    end
    if occursin(r"[/\\]", name)
        throw(ArgumentError("Variable name cannot contain '/' or '\\': $name"))
    end
end

"""
Validates namespace (no slashes, not empty if provided)
"""
function _validate_namespace(ns::Union{Nothing, String})
    if ns !== nothing
        if isempty(ns)
            throw(ArgumentError("Namespace cannot be empty string"))
        end
        if occursin(r"[/\\]", ns)
            throw(ArgumentError("Namespace cannot contain '/' or '\\': $ns"))
        end
    end
end

_fullname(ns::Union{Nothing, String}, name::String) = ns === nothing ? name : "$ns/$name"

"""
Serializes value for JSON storage (handles special types)
"""
_serialize(value::DateTime) = Dict("__type__" => "DateTime", "value" => string(value))
_serialize(value::Symbol) = Dict("__type__" => "Symbol", "value" => string(value))
_serialize(value::Date) = Dict("__type__" => "Date", "value" => string(value))
_serialize(value) = value

"""
Deserializes value from JSON storage
"""
function _deserialize(::Val{:DateTime}, value)
    val = value["value"]
    return DateTime(val)
end
function _deserialize(::Val{:Symbol}, value)
    val = value["value"]
    return Symbol(val)
end
function _deserialize(::Val{:Date}, value)
    val = value["value"]
    return Date(val)
end
function _deserialize(::Val, value)
    return value
end

# -- Event system ---------------------------------------------------

"""
    connect(ts::TempStorage, event::Symbol, callback::Function)

Registers a callback function for an event.  

# Supported events
- `:add`: triggered when a variable is added (receives: key, value)
- `:delete`: triggered when a variable is deleted (receives: key, value)
- `:expire`: triggered when a variable expires (receives: key, value)

# Example
```julia
connect(ts, :add) do key, value
    println("Added: \$key = \$value")
end
```
"""
function on(f, ts::TempStorage, event::Symbol, args...)
    lock(ts.lock) do
        v = get!(ts.listeners, event, Vector{Tuple{Function,Function}}())
        callback = f

        if !isempty(args)
            callback = (v...) -> isequal.(v, args) && f(v...)
        end
        push!(v, (f,callback))
    end
end

"""
    off(ts::TempStorage, event::Symbol, callback::Function)

Unregisters a previously registered callback for a specific event.
"""
function off(ts::TempStorage, event::Symbol, callback::Function)
    lock(ts.lock) do
        if haskey(ts.listeners, event)
            filter!(f -> f[1] !== callback, ts.listeners[event])
        end
    end
end

"""
Emits an event to all registered listeners (thread-safe)
"""
function _emit(ts::AbstractNamespace, event::Symbol, args...)
    listeners_copy = lock(ts.lock) do
        get(ts.listeners, event, Tuple{Function,Function}[]) |> copy
    end
    
    for cb in listeners_copy
        try
            cb[2](args...)
        catch e
            @warn "Event callback error for event :$event" exception=(e, catch_backtrace())
        end
    end
end

# -- Core API -------------------------------------------------------

"""
    addvar!(ts::TempStorage, value, name::String, ttl=nothing)

Adds a variable to the storage (thread-safe).  

# Arguments
- `value`: any serializable value
- `name`: variable name (cannot contain '/' or '\\')
- `ttl`: optional expiration duration (e.g. `Second(5)`, `Minute(1)`)

# Example
```julia
addvar!(ts, 42, "count", Second(60))
addvar!(ts, Dict("debug" => true), "config")
```
"""
function addvar!(ts::Namespace, value, name::String, ttl=nothing)
    _validate_name(name)
    
    key = name
    
    lock(ts.lock) do
        entry = TempEntry(value)
        entry.value = value
        if ttl !== nothing
            entry.ttl = now() + ttl
        end
    end
    
    _emit(ts, :addkey, key, value)
    return value
end
addvar!(ts::TempStorage, args...; ns="") = addvar!(ts.namespace[ns], args...)
Base.setindex!(n::AbstractNamespace, v, inds...) = addvar!(n, v, inds...)

"""
    getvar(ts::TempStorage, name::String; ns="", default=nothing)

Returns the value of a variable, or `default` if it does not exist or has expired.

# Example
```julia
count = getvar(ts, "count", ns="stats", default=0)
```
"""
function getvar(ts::Namespace, name::String; default=nothing)
    _validate_name(name)
    
    cleanup!(ts)
    key = name
    
    lock(ts.lock) do
        return get(ts.data, key, default)
    end
end
getvar(ts::TempStorage, name; default=nothing, ns="") =  getvar(ts.namespace[ns], name; default=default)
Base.getindex(ts::AbstractNamespace, name) =  getvar(ts, name)

"""
    hasvar(ts::TempStorage, name::String; ns=nothing) -> Bool

Checks whether a variable exists and has not expired.

# Example
```julia
if hasvar(ts, "session", ns="auth")
    # Session is active
end
```
"""
function hasvar(ts::Namespace, name::String)
    _validate_name(name)
    
    cleanup!(ts)
    key = name
    
    lock(ts.lock) do
        return haskey(ts.data, key)
    end
end
hasvar(ts::TempStorage, name; ns="") = hasvar(ts.namespace[ns], name)

"""
    delvar!(ts::TempStorage, name::String; ns="")

Deletes a variable if it exists.

# Example
```julia
delvar!(ts, "session", ns="auth")
```
"""
function delvar!(ts::Namespace, name::String)
    _validate_name(name)
    
    key = name
    
    value = lock(ts.lock) do
        v = pop!(ts.data, key, nothing)
        delete!(ts.expirations, key)
        v
    end
    
    if value !== nothing
        _emit(ts, :deletekey, key, value.value)
    end
end
delvar!(ts::TempStorage, name; ns="") = delvar!(ts.namespace[ns], name)
delete!(ts::AbstractNamespace, name) = delvar!(ts, name)

"""
    clear!(ts::Namespace; ns=nothing)

Clears all variables, or only those within the specified namespace.

# Example
```julia
clear!(ts)              # Clear everything
clear!(ts, ns="temp")   # Clear only "temp" namespace
```
"""
function clear!(ts::Namespace)
    keys_to_delete = lock(ts.lock) do
         clear!(ts.data)
         clear!(ts.namespace)
    end

    _emit(ts, :clear)
end

function clear!(ts::TempStorage; ns=nothing)
    if ns != nothing
        clear!(ts.namespace[ns])
    else
        lock(ts.lock) do
            clear!(ts.namespace)
            ts.namespace[""] = Namespace()
        end
    end

    _emit(ts, :clear)
end

"""
    cleanup!(ts::TempStorage)

Removes all expired variables and triggers `:expire` events (thread-safe).

This is called automatically by `getvar` and `hasvar`, but can be called
manually to force immediate cleanup.
"""
function cleanup!(ts::TempStorage)
    for ns in values(ts.namespace)
        cleanup!(ns)
    end
end
function cleanup!(ts::Namespace)
    nowtime = now()
    
    expired = lock(ts.lock) do
        [k for (k, v) in ts.data if isdefined(v, :ttl) && v.ttl < nowtime]
    end
    
    for k in expired
        val = lock(ts.lock) do
            v = get(ts.data, k, nothing)
            delete!(ts.data, k)
            v
        end
        
        if val !== nothing
            _emit(ts, :expire, k, val)
        end
    end

    for ns in values(ts.namespace)
        cleanup!(ns)
    end
end

"""
    start_auto_cleanup!(ts::TempStorage, interval=Second(60))

Starts a background task that automatically cleans up expired variables
at the specified interval.

# Example
```julia
start_auto_cleanup!(ts, Second(30))  # Cleanup every 30 seconds
```

Use `stop_auto_cleanup!(ts)` to stop the background task.
"""
function start_auto_cleanup!(ts::TempStorage, interval=Second(60))
    if ts.cleanup_active[]
        @warn "Auto-cleanup is already running"
        return
    end
    
    ts.cleanup_active[] = true
    
    ts.cleanup_task = @async begin
        try
            while ts.cleanup_active[]
                sleep(interval.value)
                if ts.cleanup_active[]
                    cleanup!(ts)
                end
            end
        catch e
            @error "Auto-cleanup task error" exception=(e, catch_backtrace())
        finally
            ts.cleanup_active[] = false
        end
    end
    
    @info "Auto-cleanup started (interval: $interval)"
end

"""
    stop_auto_cleanup!(ts::TempStorage)

Stops the automatic cleanup background task.

# Example
```julia
stop_auto_cleanup!(ts)
```
"""
function stop_auto_cleanup!(ts::TempStorage)
    if !ts.cleanup_active[]
        @warn "Auto-cleanup is not running"
        return
    end
    
    ts.cleanup_active[] = false
    
    if ts.cleanup_task !== nothing
        # Give it time to stop gracefully
        sleep(0.1)
    end
    
    @info "Auto-cleanup stopped"
end

createnamespace(ts::AbstractNamespace, name) = begin
    setindex!(ts.namespace, Namespace(), name)
    _emit(ts, :addns, name)
end

"""
    getnamespaces(ts::TempStorage) -> Vector{String}

Returns a list of all active namespaces.

# Example
```julia
namespaces = listnamespaces(ts)
println("Active namespaces: \$namespaces")
```
"""
getnamespaces(ts::AbstractNamespace) = ts.namespace
getnamespace(ts::AbstractNamespace, ns="") = getnamespaces(ts)[ns]

deletenamespace!(ts::AbstractNamespace, name) = begin
    delete!(ts.namespac, name)
    _emit(ts, :deletens, name)
end


"""
    varsdict(ts::TempStorage; ns=nothing) -> Vector{String}

Returns a list of all variable names, optionally filtered by namespace.

# Example
```julia
all_vars = listvars(ts)
auth_vars = listvars(ts, ns="auth")
```
"""
varsdict(ns::Namespace) = ns.data
function listvars(ts::TempStorage; ns="")
    cleanup!(ts)
    
    varsdict(ts.namespace[ns])
end

# TODO: Improve serialization
"""
    save!(ts::TempStorage, filepath::String)

Saves the current state to a JSON file, including expiration times.
Handles special types (DateTime, Symbol, Date) via serialization.

# Example
```julia
save!(ts, "storage_backup.json")
```
"""
save!(ts::TempStorage, filepath::String) = save!(ts, open(filepath, "w"))
function save!(ts::TempStorage, io::IO) 
    cleanup!(ts)

    for ns in values(ts.namespace)
        save!(io, ns, filepath)
    end

    data_copy, expirations_copy = lock(ts.lock) do
        (copy(ts.data), copy(ts.expirations))
    end
    
    serialized_data = Dict(k => _serialize(v) for (k, v) in data_copy)
    
    JSON.print(io, Dict(
        "data" => serialized_data,
        "expirations" => Dict(k => string(v) for (k, v) in expirations_copy),
        "saved_at" => string(now())
    ), 2)  # Pretty print with 2-space indent
    
    @info "Storage saved to $filepath"
end

"""
    load!(ts::TempStorage, filepath::String)

Loads the storage state from a JSON file.
Deserializes special types and validates expiration times.

# Example
```julia
load!(ts, "storage_backup.json")
```
"""
function load!(ts::TempStorage, filepath::String)
    if !isfile(filepath)
        throw(ArgumentError("File not found: $filepath"))
    end
    
    d = JSON.parsefile(filepath)
    
    deserialized_data = Dict{String, Any}(
        k => _deserialize(v) for (k, v) in d["data"]
    )
    
    expirations_dict = Dict{String, DateTime}()
    nowtime = now()
    expired_count = 0
    
    for (k, v) in d["expirations"]
        exp_time = DateTime(v)
        if exp_time > nowtime
            expirations_dict[k] = exp_time
        else
            # Don't load expired variables
            delete!(deserialized_data, k)
            expired_count += 1
        end
    end
    
    lock(ts.lock) do
        ts.data = deserialized_data
        ts.expirations = expirations_dict
    end
    
    @info "Storage loaded from $filepath" active_vars=length(ts.data) expired_removed=expired_count
end

end # module