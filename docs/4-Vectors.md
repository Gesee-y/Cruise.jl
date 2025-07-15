# Cruise engine v0.1.0 : Vectors math

Here we will introduce you to some Cruise maths to allow you to easily make your games.
First of all, you should import Cruise,

```julia
julia> using Cruise
```

## Vectors

Cruise define multiple types of vector. We will go through them in a hierarchycal style, from the most generic to the more specific:

- `StaticVector{T,N}` where `T` is the type and `N` the number of elements
   - `SVector{T,N} <: StaticVector{T,N}`: A static mutable vector of type `T` and length `T`.
      - `VectorType{T}`: Union type for every vector type useful for games. The data of the subtypes of this type can be accessed via `x`,`y`,`z`,`w` following the length of the vector.
         - `Vector2D{T}`: Represent every kind of 2D vector.
            - `Vec2{T} = SVector{T,2}`: A concrete type to initialize 2D vectors
               - `Vec2i = Vec2{Int64}`: Represent a 2D vector accepting only ints
               - `Vec2f = Vec2{Float32}`: Represent a 2D Vector accepting only single precision floats
         - `Vector3D{T}`: Represent every kind of 3D vector.
            - `Vec3{T} = SVector{T,3}`: A concrete type to initialize 3D vectors
               - `Vec3i = Vec3{Int64}`: Represent a 3D vector accepting only ints
               - `RGB = Vec3{Int8}`: Represent colors with 3 channels represented as `Int8`
               - `fRGB = Vec3{Float32}`: Represent colors with 3 channels represented as `Float32` going from `0` to `1`
               - `Vec3f = Vec3{Float32}`: Represent a 3D Vector accepting only single precision floats
         - `Quaternion{T}`: Represent every king of 4D vector or quaternions.
            - `Quat{T} = SVector{T,4}`: A concrete type to initialize 4D vectors or quaternions
               - `Quati = Quat{Int64}`: Represent a 4D vector accepting only ints
               - `RGBA = Quat{Int8}`: Represent colors with 4 channels represented as `Int8`
               - `fRGBA = Quat{Float32}`: Represent colors with 4 channels represented as `Float32` going from `0` to `1`
               - `Quatf = Quat{Float32}`: Represent a 4D Vector accepting only single precision floats 
   - `iSVector{T,N} <: StaticVector{T,N}`: a static immutable vector of type `T` and length `T`. Is faster than it's mutable equivalent
      - `VectorType{T}`: Union type for every vector type useful for games. The data of the subtypes of this type can be accessed via `x`,`y`,`z`,`w` following the length of the vector.
         - `Vector2D{T}`: Represent every kind of 2D vector.
            - `iVec2{T} = iSVector{T,2}`: A concrete type to initialize 2D immutable vectors
               - `iVec2i = iVec2{Int64}`: Represent an immutable 2D vector accepting only ints
               - `iVec2f = iVec2{Float32}`: Represent an immutable 2D Vector accepting only single precision floats
         - `Vector3D{T}`: Represent every kind of 3D vector.
            - `iVec3{T} = iSVector{T,3}`: A concrete type to initialize 3D immutable vectors
               - `iVec3i = iVec3{Int64}`: Represent an immutable 3D vector accepting only ints
               - `iRGB = iVec3{Int8}`: Represent an immutable color with 3 channels represented as `Int8`
               - `ifRGB = iVec3{Float32}`: Represent an immutable color with 3 channels represented as `Float32` going from `0` to `1`
               - `iVec3f = iVec3{Float32}`: Represent an immutable 3D Vector accepting only single precision floats
         - `Quaternion{T}`: Represent every king of 4D vector or quaternions.
            - `iQuat{T} = iSVector{T,4}`: A concrete type to initialize 4D immutable vectors or quaternions
               - `iQuati = iQuat{Int64}`: Represent an immutable 4D vector accepting only ints
               - `iRGBA = iQuat{Int8}`: Represent an immutable colors with 4 channels represented as `Int8`
               - `ifRGBA = iQuat{Float32}`: Represent an immutable colors with 4 channels represented as `Float32` going from `0` to `1`
               - `iQuatf = iQuat{Float32}`: Represent an immutable 4D Vector accepting only single precision floats

That was long but we did it. It's finish. Let's now see how we can use them.
It's simple to create a new Vector.

```julia
julia> a = Vec2i(10, 20)
[10, 20]

julia> b = Vec2i(-5, 47)
[-5, 47]
```

You can use regular operations on vectors such as:
   
   - **Addition**: `a+b # Output [5, 67]`.
   - **Substraction**: `a-b # Output [15, -27]`.
   - **Multiplication by a scalar**: `2a # Output [20, 40]`.
   - **Division by a scalar**: `a/2 # Output [5, 10]`.
   - **Component wise multiplication**: `a*b # Output [-50, 940]`.
   - **Dot product**: `vdot(a,b) # Output 890`
   - **Cross product**: `vcross(a,b) # Since a and b are 2D Vector, it will return a 3D vector with only the z component set, the others are 0`
   - **Normalization**: `vnormalize(a) # Only gives us the direction of a`
   - **Norm**: `vnorm(a) # Give us the length of a`
   - **Norm squared**: `vnorm_squared(a) # Gives the squared length of a. faster than norm(a)^2`
   - **Normalize and norm**: `vnormalize_and_norm(a) # Return a tuple containing the normalized a the norm of a. This is faster than callin normalize(a) and norm(a) seperately.`
   - **Getting the angle**: `vangle(a) # Return the angle of the vector with the x-axis`
   - **Angle between 2 Vector**: `v_getangle(a,b) # Return the angle between a and b.`
   - **Is normalized**: `v_is_normalized(a) # return true if the norm squared of a is 1`
   - **Orthogonality**: `v_is_orthogonal(a,b) # Return true if a and b are ortogonal to each other`
   - **Rotation**: `vrotate(a, pi/2) # Will rotate a by an angle of pi/2 radians`
   - **Rotation degree**: `vrotated(a, 90) # The same as vrotate but the angle is given in degree`
   - **Projection** : `v_getproj(a,b) # return the projection of a on b.`
   - **Reflection**: `vreflect(a,b) # Return the reflection of a with the normal b`

## Summary

Cruise provides you all the vector math you need in order to make your game. You now know:

* How to create some vectors
* How to manipulate them

* 