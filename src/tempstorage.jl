
export TempStorage, addvar!, getvar, hasvar, delvar!, clear!, save!, load!, cleanup!,
       on, off, start_auto_cleanup!, stop_auto_cleanup!, listnamespaces, listvars

using Dates, JSON

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
mutable struct TempStorage
    data::Dict{String, Any}
    expirations::Dict{String, DateTime}
    listeners::Dict{Symbol, Vector{Function}}
    lock::ReentrantLock
    cleanup_task::Union{Nothing, Task}
    cleanup_active::Ref{Bool}
end

function TempStorage()
    TempStorage(
        Dict{String, Any}(),
        Dict{String, DateTime}(),
        Dict{Symbol, Vector{Function}}(),
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
function _serialize(value)
    if value isa DateTime
        return Dict("__type__" => "DateTime", "value" => string(value))
    elseif value isa Symbol
        return Dict("__type__" => "Symbol", "value" => string(value))
    elseif value isa Date
        return Dict("__type__" => "Date", "value" => string(value))
    else
        return value
    end
end

"""
Deserializes value from JSON storage
"""
function _deserialize(value)
    if value isa Dict && haskey(value, "__type__")
        type_str = value["__type__"]
        val = value["value"]
        if type_str == "DateTime"
            return DateTime(val)
        elseif type_str == "Symbol"
            return Symbol(val)
        elseif type_str == "Date"
            return Date(val)
        end
    end
    return value
end

# -- Event system ---------------------------------------------------

"""
    on(ts::TempStorage, event::Symbol, callback::Function)

Registers a callback function for an event.  

# Supported events
- `:add` — triggered when a variable is added (receives: key, value)
- `:delete` — triggered when a variable is deleted (receives: key, value)
- `:expire` — triggered when a variable expires (receives: key, value)

# Example
```julia
on(ts, :add) do key, value
    println("Added: \$key = \$value")
end
```
"""
function on(ts::TempStorage, event::Symbol, callback::Function)
    lock(ts.lock) do
        v = get!(ts.listeners, event, Vector{Function}())
        push!(v, callback)
    end
end

"""
    off(ts::TempStorage, event::Symbol, callback::Function)

Unregisters a previously registered callback for a specific event.
"""
function off(ts::TempStorage, event::Symbol, callback::Function)
    lock(ts.lock) do
        if haskey(ts.listeners, event)
            filter!(f -> f !== callback, ts.listeners[event])
        end
    end
end

"""
Emits an event to all registered listeners (thread-safe)
"""
function _emit(ts::TempStorage, event::Symbol, args...)
    listeners_copy = lock(ts.lock) do
        get(ts.listeners, event, Function[]) |> copy
    end
    
    for cb in listeners_copy
        try
            cb(args...)
        catch e
            @warn "Event callback error for event :$event" exception=(e, catch_backtrace())
        end
    end
end

# -- Core API -------------------------------------------------------

"""
    addvar!(ts::TempStorage, name::String, value; ns=nothing, ttl=nothing)

Adds a variable to the storage (thread-safe).  

# Arguments
- `name`: variable name (cannot contain '/' or '\\')
- `value`: any serializable value
- `ns`: optional namespace for organization
- `ttl`: optional expiration duration (e.g. `Second(5)`, `Minute(1)`)

# Example
```julia
addvar!(ts, "count", 42, ns="stats", ttl=Second(60))
addvar!(ts, "config", Dict("debug" => true))
```
"""
function addvar!(ts::TempStorage, name::String, value; ns=nothing, ttl=nothing)
    _validate_name(name)
    _validate_namespace(ns)
    
    key = _fullname(ns, name)
    
    lock(ts.lock) do
        ts.data[key] = value
        if ttl !== nothing
            ts.expirations[key] = now() + ttl
        else
            # Remove expiration if updating without TTL
            delete!(ts.expirations, key)
        end
    end
    
    _emit(ts, :add, key, value)
    return value
end

"""
    getvar(ts::TempStorage, name::String; ns=nothing, default=nothing)

Returns the value of a variable, or `default` if it does not exist or has expired.

# Example
```julia
count = getvar(ts, "count", ns="stats", default=0)
```
"""
function getvar(ts::TempStorage, name::String; ns=nothing, default=nothing)
    _validate_name(name)
    _validate_namespace(ns)
    
    cleanup!(ts)
    key = _fullname(ns, name)
    
    lock(ts.lock) do
        return get(ts.data, key, default)
    end
end

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
function hasvar(ts::TempStorage, name::String; ns=nothing)
    _validate_name(name)
    _validate_namespace(ns)
    
    cleanup!(ts)
    key = _fullname(ns, name)
    
    lock(ts.lock) do
        return haskey(ts.data, key)
    end
end

"""
    delvar!(ts::TempStorage, name::String; ns=nothing)

Deletes a variable if it exists.

# Example
```julia
delvar!(ts, "session", ns="auth")
```
"""
function delvar!(ts::TempStorage, name::String; ns=nothing)
    _validate_name(name)
    _validate_namespace(ns)
    
    key = _fullname(ns, name)
    
    value = lock(ts.lock) do
        v = pop!(ts.data, key, nothing)
        delete!(ts.expirations, key)
        v
    end
    
    if value !== nothing
        _emit(ts, :delete, key, value)
    end
end

"""
    clear!(ts::TempStorage; ns=nothing)

Clears all variables, or only those within the specified namespace.

# Example
```julia
clear!(ts)              # Clear everything
clear!(ts, ns="temp")   # Clear only "temp" namespace
```
"""
function clear!(ts::TempStorage; ns=nothing)
    keys_to_delete = lock(ts.lock) do
        if ns === nothing
            collect(keys(ts.data))
        else
            prefix = "$ns/"
            [k for k in keys(ts.data) if startswith(k, prefix)]
        end
    end
    
    for k in keys_to_delete
        # Extract name from full key
        parts = split(k, '/')
        name = parts[end]
        ns_part = length(parts) > 1 ? join(parts[1:end-1], '/') : nothing
        delvar!(ts, name, ns=ns_part)
    end
end

"""
    cleanup!(ts::TempStorage)

Removes all expired variables and triggers `:expire` events (thread-safe).

This is called automatically by `getvar` and `hasvar`, but can be called
manually to force immediate cleanup.
"""
function cleanup!(ts::TempStorage)
    nowtime = now()
    
    expired = lock(ts.lock) do
        [k for (k, t) in ts.expirations if t < nowtime]
    end
    
    for k in expired
        val = lock(ts.lock) do
            v = get(ts.data, k, nothing)
            delete!(ts.data, k)
            delete!(ts.expirations, k)
            v
        end
        
        if val !== nothing
            _emit(ts, :expire, k, val)
        end
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

"""
    listnamespaces(ts::TempStorage) -> Vector{String}

Returns a list of all active namespaces.

# Example
```julia
namespaces = listnamespaces(ts)
println("Active namespaces: \$namespaces")
```
"""
function listnamespaces(ts::TempStorage)
    cleanup!(ts)
    
    lock(ts.lock) do
        namespaces = Set{String}()
        for k in keys(ts.data)
            if occursin('/', k)
                ns = split(k, '/')[1]
                push!(namespaces, ns)
            end
        end
        return sort(collect(namespaces))
    end
end

"""
    listvars(ts::TempStorage; ns=nothing) -> Vector{String}

Returns a list of all variable names, optionally filtered by namespace.

# Example
```julia
all_vars = listvars(ts)
auth_vars = listvars(ts, ns="auth")
```
"""
function listvars(ts::TempStorage; ns=nothing)
    cleanup!(ts)
    
    lock(ts.lock) do
        if ns === nothing
            return sort(collect(keys(ts.data)))
        else
            prefix = "$ns/"
            return sort([k for k in keys(ts.data) if startswith(k, prefix)])
        end
    end
end

"""
    save!(ts::TempStorage, filepath::String)

Saves the current state to a JSON file, including expiration times.
Handles special types (DateTime, Symbol, Date) via serialization.

# Example
```julia
save!(ts, "storage_backup.json")
```
"""
function save!(ts::TempStorage, filepath::String)
    cleanup!(ts)
    
    data_copy, expirations_copy = lock(ts.lock) do
        (copy(ts.data), copy(ts.expirations))
    end
    
    serialized_data = Dict(k => _serialize(v) for (k, v) in data_copy)
    
    open(filepath, "w") do io
        JSON.print(io, Dict(
            "data" => serialized_data,
            "expirations" => Dict(k => string(v) for (k, v) in expirations_copy),
            "saved_at" => string(now())
        ), 2)  # Pretty print with 2-space indent
    end
    
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