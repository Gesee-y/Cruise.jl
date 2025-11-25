# Cruise v0.3.0 documentation: Event System

Cruise provides you with 2 events systems: **`CRSubject`s**, and **[EventNotifiers.jl](https://github.com/Gesee-y/EventNotifiers.jl)**

This documentation will only cover `CRSubject`, EventNotifiers.jl already have it's own [documentation](https://github.com/Gesee-y/EventNotifiers.jl/blob/main/docs/index.md).

`CRSubject`s is a lightweight implementations of the observer pattern, you register functions in them and then you can call all of them when the `CRSubject` changes.

It allows you to easily make complex logics in your game, for example a health bar that update when the player health change:

Let's do that, a simple way to update an health bar when the player's health points change.
First let's create our subject.

```
using Cruise

HP = CRSubject(100)
```

We create now a little health system:

```julia
mutable struct HealtBar
   maxvalue:Int
   current::Int
end

HB = HealthBar(100, HP[]) # You can access data contained in a CRSubject using these brackets [] after his name
```

Now we will connect a function to it that will update our health bar object when `HP` changes

```julia
connect(HP) do hp
    HB.current = hp
end
```

So here we made a new function using the `do` syntax. This function takes into argument the value contained in the subject `HP`
THis function will just assign the new health value to the health bar.

Now let's try to modify the value of our subject:

```julia
HP[] = 90

# HB has updated his `current` field accordingly
```

Note that a more advanced way to do it is using EventNotifiers. It's a bit overkill for simple cause and have higher latency than `CRSubject`.
So for this we will also show how to do the exact same thing with EventNotifiers.jl.

First let's create our event:

```julia
@Notifyer HP_CHANGED(newhp::Int)
```

Now we since the player health points could change multiple times during a single frame, we will chage the **state** of the `Notifyer` so that only the latest change in the player health should be taken into account.

```julia
sync_latest(HP_CHANGED, 1) # 1 here is how much change should be taken into account
```

Now we will connect another function to it.

```julia
connect(HP_CHANGED) do hp
    HB.current = hp
end
```

Now when the player health change we can just do:

```julia
HP_CHANGED.emit = newhp

# HP will update accordingly
```