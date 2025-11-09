# Temporary Storage

# Temporary Storage

Cruise provides a `TempStorage`, which acts as a lightweight in-memory cache for your game.

It allows you to store temporary variables, manage their lifetime with time-to-live (TTL), organize them into namespaces, and react to changes through events — all accessible directly from your `CruiseApp`.

---

## Basic Operations

### Accessing the `TempStorage`

When you already initialized a `CruiseApp` like this:

```julia
using Cruise

app = CruiseApp()
```

It contains a `TempStorage` accessible as follows:

```julia
temp = app.temps
```

### Adding data

To add some data to a `TempStorage`, you use the following:

```julia
addvar!(temp::TempStorage, var::String, val::Any; ttl=nothing)
```

- `temp`: The temporary storage you want to add data to
- `var`: the name of the data you want to add
- `val`: the data you actually want to store
- `ttl`: how long you data should last in the storage before being deleted. `nothing` means never. It use your system clock to track expirations.

You can also use this sugar syntax:

```julia
temp[var, [ttl]] = val
```

#### Example

```julia
# Will store "warp-dest" in the temporary storage for 30 seconds
addvar!(temp, "warp-dest", 1; ttl=Dates.Second(30))

# or
temp["warp-dest", Dates.Second(30)] = 1
```

### Getting a value

To get back a value you stored, use `getvar`:

```julia
getvar(temp::TempStorage, var::String)
```
or
```julia
temp[var]
```

This will return  `nothing` if `var` is not in the temporary storage or has expired.

### Removing data

You just use:

```julia
delete!(temp::TempStorage, var::String)
```

## Namespaces 

It may happens that names conflicts in the temporary storage, for example:

```julia

# In some game logics
temp["scale"] = 2

## then in your rendering logic
temp["scale"] = Vec2(1, 2)
```

While you could use prefixes to avoid conflicts, this makes querying slower.
Namespaces solve this by separating variables into isolated groups, internally managed as independent hash tables, avoiding key collisions and speeding up lookups.

### Creating a namespace

To make a new `Namespace` you do:

```julia
createnamespace!(temp::TempStorage, name::String)
```

This returns a `Namespace` object.
Every operation valid on a `TempStorage` is also valid on a `Namespace`.

### Getting a namespace

To get a namespace, you use:

```julia
getnamespace(temp::TempStorage,  name::String)
```

It returns `nothing` if the namespace doesn't exist.

### Deleting a namespace 

To delete a namespace,  you use:

```julia
deletenamespace!(temp::TempStorage, name::String)
```

## Events

`TempStorage` and `Namespaces` support the following functions:

- `onkeyadded(f, ts_or_ns, [key])`: register the function `f` as a callback and will be called when a new key will be added. If `key` is specified, then `f` is only called if it's `key` that has been added

- `onkeydeleted(f, ts_or_ns, [key])`

- `onkeyexpired(f, ts_or_ns, [key])`

- `onnamespaceadded(f, ts_or_ns, [name])`

- `onnamespacedeleted(f, ts_or_ns, [name])`