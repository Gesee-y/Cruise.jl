# Arceus.jl

A fork of [AliceRoselia](https://github.com/AliceRoselia/Arceus.jl)'s *Arceus*, an entity management system based on magic bitboards.

[Entity-Component-System (ECS)](https://en.wikipedia.org/wiki/Entity_component_system) is a well-established architecture for managing entities by decoupling **data** (components) from **behavior** (systems). However, traditional ECS approaches suffer from query-based bottlenecks—retrieving all entities with a specific set of components can become redundant and slow, especially as the number of possible component combinations grows.

**Arceus.jl** solves this using an approach inspired by [magic bitboards](https://www.chessprogramming.org/Magic_Bitboards)—a technique originally used in chess engines to precompute move lookups. With it, Arceus offers lightning-fast, constant-time (`O(1)`) behavior resolution for any component combination.

## Installation

**Stable version**

```julia
julia> ]add Arceus
```

**Development version**

```julia
julia> ]add https://github.com/Gesee-y/Arceus.jl
```

## Features

* **Constant-Time Behavior Lookup**
  Precompute all possible behaviors for entities and retrieve them instantly based on their components.

* **Caching of Magic Numbers**
  Magic numbers used for lookups are cached to disk (CSV), ensuring deterministic, reproducible, and fast reinitialization.

* **Compatibility**
  Works with any archetype-based ECS using bitmasking or similar approaches for component storage.

* **Fine-Grained Bit Manipulation**
  Define custom bit ranges for component pools, explicitly control trait positions, and encode trait dependencies.

## Example

```julia
using Arceus

#Traitpool must be defined at compile time.

@traitpool "ABCDEF" begin
    @trait electro
    @trait flame #Defining trait without bits.
    @trait laser 2 #Defining trait with a specified bit (from the right or least significant.)
    @subpool roles begin
        @trait attacker
        @trait support
        
    end
    @subpool meta 16-32 begin #Subpool can be defined with a specified number of bits, but for a concrete subpool, the number of bits can be defined.
        @trait earlygame
        @trait midgame
        @trait lategame
    end
    @abstract_subpool reserve1 33-48 #Defining start and finish bits.
    @abstract_subpool reserve2 8 #Defining the size, but not the sub_trait.
end

#This will register the variable at compile time and construct a trait pool at runtime.
@make_traitpool "ABCDEF" Pokemon begin
    @trait electro #Creating trait pool with the following traits.
    @trait flame
end

#Subpool also must be defined in the global scope.
@subpool "Biome" "ABCDEF".reserve1.biome_preference begin
    @trait beach_preference
    @trait ice_preference
    @trait volcanic_preference
end
#Defining concrete subpool. 
@subpool "Meta" "ABCDEF".meta

@make_subpool "Biome" biometraits Pokemon
@make_subpool "Meta" metatraits Pokemon
@make_subpool "Biome" biometraits2 begin
    @trait beach_preference 1
    @trait ice_preference 0
    @trait volcanic_preference
end

#This "registers" subpool.
#Usage...
function x(biometraits3::get_trait_pool_type("Biome"))
    @register_subpool "Biome" biometraits3 #Since this is a subpool.
    #Use @register_traitpool for a non-subpool trait pool.
end

#This joins the subpools to their parent traitpool (Presume parent, otherwise they write whatever bits they happen to occupy).
#This syntax is used for the sake of consistent syntax across the entire package.
@join_subpools Pokemon begin
    @subpool biometraits2
    @subpool metatraits
end

#You can modify and copy trait pools.

@copy_traitpool Pokemon Pokemon2
@copy_traitpool Pokemon Pokemon3
@copy_traitpool Pokemon Pokemon4
@make_traitpool "ABCDEF" X
@copy_traitpool Pokemon X
#You can use copy_traitpool to existing trait pools too.

@settraits Pokemon2 begin
    @trait electro 
    @trait roles.attacker 1
    @trait roles.support X
    @trait meta.earlygame X
end

@addtraits Pokemon3 begin
    @trait electro 
    @trait roles.attacker 1
    @trait roles.support X
    @trait meta.earlygame X
end

@removetraits Pokemon4 begin
    @trait electro 
    @trait roles.attacker 1
    @trait roles.support X
    @trait meta.earlygame X
end

f1 = @lookup k "ABCDEF" begin
    out = 1.0
    if @hastrait k.electro
        out *= 2
    end
    if @hastrait k.flame
        out *= 1.5 
    end
    if @hastrait k.meta.earlygame
        out *= 1.2
    end
    return out
end

#If the variable is not registered, it is not seen in the module, the result is error finding variable of that name.
@register_variable f1
#We then can finally make the lookup function.
effectiveness = @make_lookup f1
lookup_val = effectiveness[Pokemon]

println(lookup_val)
```

## Known Limitations

* Generating the magic numbers for the first time is compute-intensive. However, this is a one-time cost, as results are cached for future runs.

## Contributions

All contributions are welcome! Feel free to submit pull requests or open issues.

And don't forget to support the original author of this system, [AliceRoselia](https://github.com/AliceRoselia).

### Julia Discourse post

Arceus: A lightning fast behavioural system

Hello guys.
Happy to show you today a new package, [Arceus](https://github.com/Gesee-y/Arceus.jl). Originally made by [AliceRoselia](https://github.com/AliceRoselia) (or @Tarnie_GG_Channie as she is called on this discourse), this fork offer a crazy fast way to get behaviours for an entity given a set of components (represented as a UInt64). This approach rely on [magic bitboards](https://www.chessprogramming.org/Magic_Bitboards), an optimization technique often used in chess engines.

For the features, we have:

* **Constant-Time Behavior Lookup**
  Precompute all possible behaviors for entities and retrieve them instantly based on their components.

* **Caching of Magic Numbers**
  Magic numbers used for lookups are cached to disk (CSV), ensuring deterministic, reproducible, and fast reinitialization.

* **Compatibility**
  Works with any archetype-based ECS using bitmasking or similar approaches for component storage.

* **Fine-Grained Bit Manipulation**
  Define custom bit ranges for component pools, explicitly control trait positions, and encode trait dependencies.

Here is an Example

```julia
using Arcane

@traitpool "EndingTrait" begin
    @trait start
    @trait meetX
    @trait gotSaber #Defining trait without bits.
    @trait lostAlly 2 #Defining trait with a specified bit (from the right or least significant.)
    @subpool side begin
        @trait good
        @trait evil 
    end
end

@make_traitpool "EndingTrait" GameEnding begin
    @trait start
end

@addtrait GameEnding begin
    @trait meetX
    @trait lostAlly
    @trait side.good
end

# val is just an example, may be replaced by any more concrete trigger
f1 = @lookup END "EndingTraits" begin
    val = UInt(0)
    if @hastrait END.start
        val |= 1
    end
    if @hastrait END.meetX
        val |= 2 
    end
    if @hastrait END.gotSaber
        val |= 4
    end
    if @hastrait END.lostAlly
        val |= 8
    end
    if @hastrait END.side.good
        val |= 64
    end
    if @hastrait END.side.evil
        val |= 128
    end
    return val
end

#If the variable is not registered, it is not seen in the module, the result is error finding variable of that name.
@register_variable f1
#We then can finally make the lookup function.
ending = @make_lookup f1
lookup_val = ending[GameEnding]

println(lookup_val)
```

This allow ligthing fast O(1) behaviour lookup (**< 10ns**) which can be used for complex pattern matching.

Knowm limitations are :
- The magic number computation is pretty heavy. You should do it at boot time. Once done for the first time, this pakage will cache it in a CSV file for reuse
- You are limited to 64 bits. Above this the magic bitboard trick is no more valid.

Feel free to contribute to this package, don't forget to support the original author [AliceRoselia](https://github.com/AliceRoselia).

Ton post est bien structuré, informatif et clair. Voici quelques ajustements pour le rendre plus professionnel, fluide et idiomatique dans le style souvent attendu sur [Julia Discourse](https://discourse.julialang.org/). Ces suggestions incluent :

* Petites corrections grammaticales
* Plus de fluidité dans la présentation
* Ton plus technique et direct, comme tu l'apprécies

---

### Arceus.jl — A Lightning-Fast Behavior Resolution System

Hi all,

I'm happy to present [Arceus.jl](https://github.com/Gesee-y/Arceus.jl), a high-performance fork of [AliceRoselia](https://github.com/AliceRoselia)'s original package [Arceus](https://github.com/AliceRoselia/Arceus.jl), which introduces a novel way to resolve behaviors for entities based on their component sets—using [magic bitboards](https://www.chessprogramming.org/Magic_Bitboards), an optimization technique originally used in chess engines for O(1) move lookups.

Arceus.jl provides constant-time behavior resolution for ECS-style setups where entities are encoded as `UInt64` bitfields. This is especially useful in games, simulations, or other systems where thousands of entities need to be matched to behaviors in real-time.

---

### Features

* **O(1) Behavior Lookup**
  Behaviors are precomputed for all possible component combinations, enabling instant retrieval.

* **Magic Bitboard Caching**
  Magic numbers are expensive to compute, so they're deterministically cached to disk (CSV), enabling fast startup on subsequent runs.

* **ECS Compatibility**
  Works with any archetype-based ECS that represents components using bitmasks or similar binary encodings.

* **Fine-Grained Bit Control**
  You can allocate custom bit ranges for component pools, set precise trait positions, and manage trait dependencies.

---

### Example

Here's a simplified usage example:

```julia
using Arceus

@traitpool "EndingTrait" begin
    @trait start
    @trait meetX
    @trait gotSaber
    @trait lostAlly at 2
    @subpool side begin
        @trait good
        @trait evil 
    end
end

@make_traitpool GameEnding from "EndingTrait" begin
    @trait start
end

@addtrait GameEnding begin
    @trait meetX
    @trait lostAlly
    @trait side.good
end

f1 = @lookup END "EndingTrait" begin
    val = UInt(0)
    if @hastrait END.start
        val |= 1
    end
    if @hastrait END.meetX
        val |= 2 
    end
    if @hastrait END.gotSaber
        val |= 4
    end
    if @hastrait END.lostAlly
        val |= 8
    end
    if @hastrait END.side.good
        val |= 64
    end
    if @hastrait END.side.evil
        val |= 128
    end
    return val
end

@register_variable f1
ending = @make_lookup f1

println(ending[GameEnding])
```

This allows sub-10ns behavior lookup on modern hardware.

---

### Known Limitations

* **Heavy Initial Computation**: Magic numbers are expensive to generate. It's best to compute them once during initialization—after that, they are cached to a CSV file.
* **64-bit Limit**: The system operates on `UInt64`, meaning you're limited to 64 component flags. Beyond that, the magic bitboard trick doesn't apply.

---

### Links

* GitHub: [https://github.com/Gesee-y/Arceus.jl](https://github.com/Gesee-y/Arceus.jl)
* Original author: [AliceRoselia](https://github.com/AliceRoselia) (@Tarnie_GG_Channie)

---

### Contribute

Contributions are very welcome—whether it's suggestions, PRs, or feedback. And please consider supporting the original author of the system!

---

### Summary

If you're working with ECS architectures and need lightning-fast behavior resolution for complex trait combinations, Arceus.jl might be worth a look. Let me know what you think, and feel free to ask questions or open issues.

