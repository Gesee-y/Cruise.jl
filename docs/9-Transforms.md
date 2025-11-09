# Cruise v0.3.0: Transformations and coordinate system 

## Transforms 

Transformations allows you to move, rotate your object.

Each renderable object has one in the background 

```julia
# assume you have already create an app, imported HZPlugin and merged it

obj = Object2D(Vec2f(0,0), Vec2f(1, 1))
println(obj.transform)
```

The transform object is as follow:

```
Transform{N}
     space :: VectorSpace{N,Float64}
     position :: SVector{Float32,N}
     angle :: Float64
     rotation_axis::Vec3{Float32}
     scale :: SVector{Float32,N}
     matrix :: Mat4{Float32}
```

- `space` is the vector space in which the transformation
occur, 
- `position` is the emplacement of the object relatively to his space
- `angle` is used for 2d rotations
- `rotation_axis` are the axis on which the object rotation occurs (useful for 3d)
- `scale` is the size of the object along each dimension
- `matrix` is the final transformation matrix

The transformation matrix isn't automatically updated when data in the `Transform` change so you need to call `updated_transform_matrix!` on it.

## Coordinate systems

**Coordinate systems** allow you to do compplex calculations in the most convenient representation.
Cruise provides you with:

- `PolarCoord`
- `BipolarCoord`
- `CylindricalCoord`
- `SphericalCoord`
- `CartesianCoord`

To create your own system all you have to do is to create your sub type 
of it (`MyCoordinateSystem <: CoordinateSystem`) and then set the methods ToCartesian(::MyCoordinateSystem) and 
you are done

```julia-repl

julia> struct PolarCoordinate <: CoordinateSystem
                  r :: Float64
                  phi :: Float64
       end

julia> ToCartesian(coord::PolarCoordinate) = begin
            x = cos(coord.phi) * coord.r
            y = sin(coord.phi) * coord.r

            return CartesianCoord{2}(x,y) # To cartesian should return a cartesian coordinate struct for efficiency
           end

julia> # Polar coordinate can now be used for any calculation involving a Coordinate system

```

---