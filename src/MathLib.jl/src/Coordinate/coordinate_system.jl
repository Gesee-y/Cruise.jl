## This will contain all the necessary for creatin coordinate systems ##

"""
	abstract type CoordinateSystem

The base type for any coordinate system. to create your own system all you have to do is to create your sub type 
of it (`MyCoordinateSystem <: CoordinateSystem`) and then set the methods ToCartesian(::MyCoordinateSystem) and 
you are done

# Example
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
"""
abstract type CoordinateSystem end

"""
	abstract type ColorSpace

A Base type to define different color space. When you want to create your own color space, you make it subtype the 
ColorSpace type (MyColorSpace <: ColorSpace) and then you define ToRGB or ToRGBA for your type

#Example

```julia-repl

julia> struct HSV <: ColorSpace
			Hue::Float64
			Saturation::Float64
			V :: Float64
	   end

julia> ToRGBA(color::HSV)
"""
abstract type ColorSpace end

"""
	struct CartesianCoordinate{N} <: CoordinateSystem
		components :: NTuple{N,Real}

A simple struct to contain N-dimensional cartesian vector coordinate	
"""
struct CartesianCoord{N} <: CoordinateSystem
	components :: NTuple{N,Real}

	## Constructors ##

	CartesianCoord{N}(elt::Vararg{Number,N}) where N = new{N}(elt)
	CartesianCoord{N}(elt::Number...) where N = length(elt) != N ? throw(
		DimensionMismatch("Cartesian coordinate of $N elements by receive $(length(elt)) arguments")) : new{N}(elt)
end

"""
	struct PolarCoord <: CoordinateSystem
		r :: Float64
		phi :: Float64

A struct to easily contain polar coordinate from the center of the cartesian plan and the x-axis.

"""
struct PolarCoord <: CoordinateSystem
	r :: Float64
	phi :: Float64

	## Constructors ##

	PolarCoord(r::Real,angle::Real) = new(r,angle)
	PolarCoord(vec::Vector2D) = new(sqrt(vec.x^2+vec.y^2),atan(vec.y,vec.x))
end

"""
	struct BipolarCoord <: CoordinateSystem
		r :: Float64
		phi :: Float64

A struct to easily represent bipolar coordinate with a distance of 2 by default.

"""
struct BipolarCoord <: CoordinateSystem
	phi1 :: Float64
	phi2 :: Float64

	## Constructors ##

	BipolarCoord(r1::Real,r2::Real) = new(r1,r2)
	function BipolarCoord(vec::Vec2,c = bipolar_distance())
		r1 = sqrt(vec.y^2 + (vec.x + c)^2)
		r2 = sqrt(r1^2 - 4c*vec.x)
		new(r1,r2)
	end
end

"""
	struct CylindricalCoord <: CoordinateSystem
		r :: Float64
		phi :: Float64
		z :: Float64
	end

A struct to represent cylindrical coordinate.
"""
struct CylindricalCoord <: CoordinateSystem
	r :: Float64
	phi :: Float64
	z :: Float64

	CylindricalCoord(r,phi,z) = new(r,phi,z)
	function CylindricalCoord(vec::Vector3D)
		r,phi = sqrt(vec.x^2+vec.y^2),atan(vec.y,vec.x)
		z = vec.z
		new(r,phi,z)
	end
end

"""
	struct SphericalCoord <: CoordinateSystem
		r :: Float64
		phi :: Float64
		z :: Float64
	end

A struct to represent Spherical coordinate.
"""
struct SphericalCoord <: CoordinateSystem
	r :: Float64
	phi :: Float64
	theta :: Float64

	SphericalCoord(r,phi,theta) = new(r,phi,theta)
	function SphericalCoord(vec::Vector3D)
		r,phi = sqrt(vec.x^2+vec.y^2+vec.z^2),atan(vec.y,vec.x)
		theta = atan(vec.z,r)
		new(r,phi,theta)
	end
end

bipolar_distance() = 2

"""
	ToCartesian(C::CoordinateSystem)

Convert the coordinate system C to cartesian coordinate system.
"""
ToCartesian(C::CartesianCoord) = C

ToCartesian(C::PolarCoord) = begin
	x = cos(C.phi) * C.r
	y = sin(C.phi) * C.r

	CartesianCoord{2}(x,y)
end

ToCartesian(C::CylindricalCoord) = begin
	x = cos(C.phi) * C.r
	y = sin(C.phi) * C.r
	z = C.z
	CartesianCoord{3}(x,y,z)
end

ToCartesian(C::SphericalCoord) = begin
	x = C.r * cos(C.phi) * sin(C.theta)
	y = C.r * sin(C.phi) * cos(C.theta)
	z = C.r * cos(theta)
	CartesianCoord{3}(x,y,z)
end

ToCartesian(C::BipolarCoord,s=1,d = bipolar_distance()) = begin
	x = (2d * sinh(C.phi1))/(cosh(C.phi1) - cos(C.phi2))
	y = (2d * sin(C.phi2))/(cosh(C.phi1) - cos(C.phi2))

	#x = (C.r1^2 + C.r2^2) / 4d
	#y = s*sqrt(C.r1^2 - (x + d)^2)

	CartesianCoord{2}(x,y)
end