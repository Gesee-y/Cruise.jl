# Cruise engine v0.1.0: Hello Cruise !!

In this section, we will set a basic typical Cruise file.
First of all, you have to install it if not already done:

```julia
julia> ]add Cruise
```

for the development version:

```julia
julia> ]add https://github.com/Gesee-y/Cruise.jl
```

Once you are done, you should be able to import the package. It takes some time to import.

```julia
julia> using Cruise
```

Now we can finally call our function to test if everything is going well:

```julia
julia> HelloCruise!!() # You can pass this function one argument like :en, :fr, :ja, :hi, :zh
```