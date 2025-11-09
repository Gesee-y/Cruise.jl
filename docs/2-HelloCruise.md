# Cruise Engine v0.1.5 – Hello Cruise!!

In this section, we will set up a minimal Cruise application to verify that everything works as expected.

## Installation

First, install the engine. If you haven't already:

```julia
julia> ]add Cruise
```

For the latest development version:

```julia
julia> ]add https://github.com/Gesee-y/Cruise.jl
```

## Getting Started

After installation, load the package:

```julia
julia> using Cruise
```

Now you're ready to run your first Cruise function:

```julia
julia> HelloCruise!!()  # You can optionally pass a language symbol: :en, :fr, :ja, :hi, :zh
```

If everything is set up correctly, Cruise should display a greeting text.
