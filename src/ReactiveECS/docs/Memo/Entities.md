## Entities

Entities are sort of object in our ECS. We can attach to their ID Components.
In this ECS, entities typically contains :
   - And ID
   - A set of his components
   - A ref to the world
   - His archetype

Then we should be able to search components

Now, as for the parent-child relationship, we need some way to represent that/
We can add an array for that in

get tree : 5.599 ns (0 allocations: 0 bytes)
add child : 10.275 ns (0 allocations: 0 bytes)
remove child : 5.599 ns (0 allocations: 0 bytes)
get children : 8.874 ns (0 allocations: 0 bytes)
get id :5.599 ns (0 allocations: 0 bytes)

create 1 entity with 2 components (initialized): 1.21 us
create 1 entity with 2 component (uninitialized): 603 ns
create 10k entity with 2 component (initialized) : 5.5ms
create 10k entity with 2 component (uninitialized) : 70 us

delete 1 entity with 2 component: 834 ns

create a query : 3.3 us

do a translation on 1k entities : 1.5 us
do a translation on 100k entities : 145 us

# ReactiveECS.jl v2.0.0: Breaking Changes for Massive Performance Boosts

Hi everyone!

I'm happy to present **[ReactiveECS.jl](https://github.com/Gesee-y/ReactiveECS.jl/tree/refactor) v2.0.0**! For those unfamiliar with the package, you can check out the [original post](https://discourse.julialang.org/t/recs-a-reactive-ecs-framework-for-high-performance-simulations-in-julia/130098/17).

This new version follows [v1.0.0](https://discourse.julialang.org/t/reactiveecs-jl-v1-0-0-powerful-reactive-ecs-balancing-flexibility-and-performances/130216), which received heavy criticism on the Flecs Discord—but those critiques gave me **valuable insight** on how to drastically improve both speed and architecture.

---

## What's Changed

The **core philosophy** of the package remains: systems are reactive and can run **asynchronously or in parallel**, completely **independent** from each other. You can dynamically add/remove systems at runtime and even inject them into a live pipeline.

The **main evolution** lies in how **data is stored**, introducing a unique feature: **partitioning**.

### Partitioning: Efficient Archetype Layout

Each archetype is now represented as a **range within a central storage table**, which dramatically reduces memory fragmentation and makes pooling straightforward. Here's a conceptual illustration:

```
        INTERNAL STORAGE
 _______________________________________________________
|   |     Health    |     Transform    |    Physic     |
|-------------------------------------------------------
|   |      hp       |    x    |    y   |   velocity    |
|-------------------------------------------------------
| 1 |     100       |   1.0   |  1.0   |      //       |
|-------------------------------------------------------
| 2 |     150       |   1.0   |  1.0   |      //       |
|-------------------------------------------------------
| 3 |     ___       |   ___   |  ___   |      //       |
|-------------------------------------------------------
| 4 |     ___       |   ___   |  ___   |      //       |
|-------------------------------------------------------
| 5 |     50        |  -5.0   |  1.0   |     1.0       |
|-------------------------------------------------------
| 6 |     50        |  -5.0   |  1.0   |     1.0       |
|-------------------------------------------------------
```

* Rows 1–4: partition for entities with `Health` and `Transform`

  * Rows 1–2 are **active**, 3–4 are **pooled**
* Rows 5–6: partition for entities with `Health`, `Transform`, and `Physic`

This design allows:

* Very fast entity creation
* Simple pooling (just invalidate IDs outside of range)
* Efficient component add/remove via internal swaps

---

## ✍️ New API Example

```julia
using ReactiveECS

@component Health begin
   hp::Int
end

@component Transform begin
    x::Float32
    y::Float32
end

@component Physic begin
   velocity::Float32
end

@component Status begin
    dirty::Int
end

@system PhysicSystem

function ReactiveECS.run!(world, ::PhysicSystem, query)
    
    # Getting components, the API for may change in the future but this will always works
    transforms = get_component(world, :Transform)
    physics = get_component(world, :Physic)
    x = transforms.x
    velocities = physics.velocity

    for partition in query

      # We get every entities range matching our query
      zones::Vector{TableRange} = partition.zones
      for zone in zones
         range = get_range(zone)

         # Your optimizations (@inbounds, @threads, @simd, @turbo, etc.)
         for i in range
            x[i] += velocities[i]
         end
      end
   end
end

ecs = ECSManager()
register_component!(ecs, Health)
register_component!(ecs, Transform)
register_component!(ecs, Physic)
register_component!(ecs, Status)

e = create_entity!(ecs, (Health = Health(50), Physic = Physic(0.0), Transform = Transform(0,0)))

# Then this can be processed normally.
q = @query(ecs, Transform & ~Status)

physic_sys = PhysicSystem()

subscribe!(ecs, physic_sys, @query(ecs,Transform & Physic))

run_system!(physic_sys)

dispatch_data(ecs) # Will call every system
blocker(ecs) # To wait for alll systems to finish if necessary.
```

### Notes:

* `OR (|)` in queries is **not supported** and likely never will be.
  Why? Because components can be accessed at any time, so complex query logic isn't needed.

---

## Performance Benchmarks


**Test Configuration**:

* **CPU**: Intel Pentium T4400 @ 2.2 GHz
* **RAM**: 2 GB DDR3
* **OS**: Windows 10
* **Julia**: v1.10.5
* **Threads**: 2

Reference benchmarks: [https://github.com/abeimler/ecs_benchmark](https://github.com/abeimler/ecs_benchmark)

> Only creation and deletion are compared.
> "Update" benchmarks have known issues and were excluded.

| Operation                                     | ReactiveECS v2 | Notes                                |
| --------------------------------------------- | -------------- | ------------------------------------ |
| Create 1 entity (2 components, initialized)   | **1.16 µs**    | *Fastest among tested ECSs*          |
| Create 1 entity (2 components, uninitialized) | **603 ns**     | *Fastest overall*                    |
| Create 10k entities (initialized)             | **5.3 ms**     | *\~3.7× faster than Overseer*        |
| Create 10k entities (uninitialized)           | **70 µs**      | *Best in class*                      |
| Delete 1 entity (2 components)                | **834 ns**     | *Fastest deletion*                   |
| Create a query                                | **3.3 µs**     | Scales with archetypes, negligible   |
| Update 1k entities (translation)              | **1.5 µs**     | 18× faster than Overseer             |
| Update 100k entities (translation)            | **145 µs**     | vs. 2.7ms for Overseer, 163µs for v1 |

ReactiveECS v2 is well-suited for handling **millions of entities** efficiently.

---

## Known Limitations

* **Higher memory usage**: Central table layout means every entity reserves slots for all components, even unused ones.
* **Parallelism isn't finalized**: Race conditions can still happen when modifying data during system execution or memory swaps. This will be addressed soon.

---

## Contributions Welcome

Feel free to:

* Look at the source
* File issues
* Open PRs

More docs, comparisons, and tutorials are coming soon.

And if you like the project, a ⭐ on GitHub is always appreciated!

---

## Summary

ReactiveECS v2 brings a **major architectural improvement**, **top-tier performance**, and a **clear API**, all while staying reactive and dynamic. Whether you're building simulations, games, or experiments, this ECS is built to scale.

Let me know what you think! Feedback, questions, and challenges are welcome.
