# Use the macros @std140 and @std430 to automatically pad your struct to match its GPU layout.
# The struct that is generated holds a byte array on the heap
#    and offers properties to get/set fields by updating this byte array.
# It can also be automatically converted to a pointer for C calls/GPU uploads.

"
Some kind of bitstype data, laid out in a way that OpenGL/GLSL can understand.
While the structs themselves are immutable, they are backed by a mutable array
    so you can set their properties.

To pass it into a C function, wrap it with a `Ref()` call.
To create an array of your block type `T`, construct `StaticBlockArray` with either
    `StaticBlockArray{T}(bytes::AbstractVector{UInt8})` or
    `StaticBlockArray{N, T}()`.

For simplicity, the buffer's bytes will always be filled with 0xAA by default,
    and the `==` operator is defined to do fast bytewise comparison.
"
abstract type AbstractOglBlock end
abstract type OglBlock_std140 <: AbstractOglBlock end
abstract type OglBlock_std430 <: AbstractOglBlock end
#TODO: Dynamically support both 140 and 430 for each block type

export AbstractOglBlock, OglBlock_std140, OglBlock_std430


#  Interface:  #


"Gets the layout type of a struct (or struct type). An example return value is `OglBlock_std140`"
block_mode(a::AbstractOglBlock) = block_mode(typeof(a))
block_mode(::Type{<:OglBlock_std140}) = OglBlock_std140
block_mode(::Type{<:OglBlock_std430}) = OglBlock_std430

"
Block structs (and block arrays) have a type parameter for the kind of array backing their data.
This function strips that parameter from the type.
"
block_simple_type(::Type{<:AbstractOglBlock})::UnionAll = error()

"
Gets the total byte-size of the given struct (or array property), including padding.
Use this instead of `sizeof()`.

For convenience, falls through to `sizeof()` for non-block data types.
"
block_byte_size(x::AbstractOglBlock) = block_byte_size(typeof(x))
block_byte_size(T) = if isbitstype(T)
    sizeof(T)
elseif T <: StaticBlockArray
    error("Must provide all type-parameters to `StaticBlockArray`; provided: ", T)
else
    error("Not bitstype: ", T)
end
block_byte_size(T::Type{<:AbstractOglBlock}) = error("Not implemented: ", T)

"Gets the amount of padding in the given struct, in bytes"
block_padding_size(b::AbstractOglBlock) = block_padding_size(typeof(b))
block_padding_size(T::Type{<:AbstractOglBlock}) = error("Not implemented: ", T)

block_alignment(b::AbstractOglBlock) = block_alignment(typeof(b))
block_alignment(T::Type{<:AbstractOglBlock}) = error("Not implemented: ", T)

const BUFFER_FIELD_NAME = Symbol("raw byte buffer")
"Gets the bytes of a block, as a mutable array of `UInt8`"
block_byte_array(b::AbstractOglBlock)::AbstractVector{UInt8} = getfield(b, BUFFER_FIELD_NAME)

"Returns the type of an `AbstractOglBlock`'s property"
@inline block_property_type(b::AbstractOglBlock, name::Symbol) = block_property_type(typeof(b), Val(name))
@inline block_property_type(T::Type{<:AbstractOglBlock}, name::Symbol) = block_property_type(T, Val(name))
@inline block_property_type(T::Type{<:AbstractOglBlock}, Name::Val) = error(T, " has no property '", val_type(Name))

"Returns a tuple of the type for each named property from `Base.propertynames`"
block_property_types(b::AbstractOglBlock) = block_property_types(typeof(b))
block_property_types(T::Type{<:AbstractOglBlock}) = error(T, " didn't implement ", block_property_types)


"
Emits declarations of the fields of an OpenGL struct or block,
    based on the Julia struct you created with `@std140` or `@std430`
"
function glsl_decl(T::Type{<:AbstractOglBlock},
                   glsl_type_names::Dict{Type, String} = Dict{Type, String}()
                   ; separator::String = "\n\t"
                  )::String
    @bp_check(!isabstracttype(T),     T, " is abstract")
    return sprint() do io
        for (i, (name, type)) in enumerate(zip(propertynames(T), block_property_types(T)))
            if i > 1
                print(io, "\n", separator)
            end
            print(io, glsl_type_decl(type, string(name), glsl_type_names), ";")
        end
    end
end


"A facade for a mutable array of items within an `AbstractOglBlock`"
abstract type BlockArray{T, TMode<:AbstractOglBlock, TByteArray<:AbstractVector{UInt8}} <: AbstractVector{T} end

"A facade for a mutable array of items within an `AbstractOglBlock`, of static size"
struct StaticBlockArray{N, T, TMode<:AbstractOglBlock, TByteArray<:AbstractVector{UInt8}} <: BlockArray{T, TMode, TByteArray}
    buffer::TByteArray # Use same field name as the blocks themselves, for convenience
end
block_static_array_length(::Type{<:StaticBlockArray{N}}) where {N} = N
block_simple_type(::Type{<:StaticBlockArray{N, T, TMode}}) where {N, T, TMode} = StaticBlockArray{N, T, TMode}



export block_mode, block_simple_type, block_static_array_length,
       block_byte_size, block_padding_size, block_alignment,
       block_byte_array, block_property_type, block_property_types,
       glsl_decl,
       BlockArray, StaticBlockArray


#  Internals:  #

Buffer(can_change_data_from_cpu::Bool, T::Type{<:Union{AbstractOglBlock, StaticBlockArray}}
       ; recommend_storage_on_cpu::Bool = false
      ) = Buffer(block_byte_size(T), can_change_data_from_cpu, recommend_storage_on_cpu)

Buffer(can_change_data_from_cpu::Bool,
       data::AbstractOglBlock
       ; recommend_storage_on_cpu::Bool = false
      ) = Buffer(can_change_data_from_cpu, block_byte_array(data); recommend_storage_on_cpu=recommend_storage_on_cpu)
Buffer(can_change_data_from_cpu::Bool,
       data::BlockArray
       ; recommend_storage_on_cpu::Bool = false
      ) = Buffer(can_change_data_from_cpu, block_byte_array(data); recommend_storage_on_cpu=recommend_storage_on_cpu)

"Sets a buffer's data to contain the given `@std140` or `@std430` struct"
function set_buffer_data(buffer::Buffer, data::AbstractOglBlock, buffer_first_byte::Integer=1)
    set_buffer_data(buffer, block_byte_array(data), buffer_first_byte)
end
"Gets a buffer's data as the given `@std140` or `@std430` struct type"
function get_buffer_data(b::Buffer, T::Type{<:AbstractOglBlock},
                         buffer_first_byte::Integer = 1
                        )::T
    arr::Vector{UInt8} = get_buffer_data(b, (UInt8, block_byte_size(T)), buffer_first_byte)
    return T{typeof(arr)}(arr)
end

"Sets a buffer's data to contain the given `BlockArray`"
function set_buffer_data(buffer::Buffer, data::BlockArray, buffer_first_byte::Integer=1)
    set_buffer_data(buffer, block_byte_array(data), buffer_first_byte)
end
"
Gets a buffer's data as a kind of `BlockArray`,
    for data mode `OglBlock_std140` or `OglBlock_std430`.
"
function get_buffer_data(b::Buffer,
                         TOut::Type{StaticBlockArray{N, T, TMode}},
                         buffer_first_byte::Integer = 1
                        )::T where {N, T, TMode}
    arr::Vector{UInt8} = get_buffer_data(
        b,
        (UInt8, block_array_element_stride(T) * N),
        buffer_first_byte
    )
    return TOut{typeof(arr)}(arr)
end


glsl_type_decl(T::Type                        , name, struct_lookup::Dict{Type, String})              = "$(glsl_type_decl(T, struct_lookup)) $name"
glsl_type_decl( ::Type{StaticBlockArray{N, T}}, name, struct_lookup::Dict{Type, String}) where {N, T} = "$(glsl_type_decl(T, struct_lookup)) $name[$N]"

glsl_type_decl(::Type{Bool}, struct_lookup::Dict{Type, String}) = "bool"
glsl_type_decl(::Type{Int32}, struct_lookup::Dict{Type, String}) = "int"
glsl_type_decl(::Type{Int64}, struct_lookup::Dict{Type, String}) = "int64_t"
glsl_type_decl(::Type{UInt32}, struct_lookup::Dict{Type, String}) = "uint"
glsl_type_decl(::Type{UInt64}, struct_lookup::Dict{Type, String}) = "uint64_t"
glsl_type_decl(::Type{Float32}, struct_lookup::Dict{Type, String}) = "float"
glsl_type_decl(::Type{Float64}, struct_lookup::Dict{Type, String}) = "double"
glsl_type_decl(::Type{Vec{N, Bool}}, struct_lookup::Dict{Type, String}) where {N} = "bvec$N"
glsl_type_decl(::Type{Vec{N, Int32}}, struct_lookup::Dict{Type, String}) where {N} = "ivec$N"
glsl_type_decl(::Type{Vec{N, UInt32}}, struct_lookup::Dict{Type, String}) where {N} = "uvec$N"
glsl_type_decl(::Type{Vec{N, Float32}}, struct_lookup::Dict{Type, String}) where {N} = "vec$N"
glsl_type_decl(::Type{Vec{N, Float64}}, struct_lookup::Dict{Type, String}) where {N} = "dvec$N"
glsl_type_decl(::Type{<:Mat{C, R, Float32}}, struct_lookup::Dict{Type, String}) where {C, R} = "mat$(C)x$(R)"
glsl_type_decl(::Type{<:Mat{C, R, Float64}}, struct_lookup::Dict{Type, String}) where {C, R} = "dmat$(C)x$(R)"
glsl_type_decl(T::Type{<:AbstractOglBlock}, struct_lookup::Dict{Type, String}) = get(struct_lookup, T,
    # Stripping the module path from the type name is tricky.
    if T isa UnionAll
        string(T.body.name.name)
    elseif T isa DataType
        string(T.name.name)
    else
        error("Unexpected: ", typeof(T))
    end
)


const BLOCK_DEFAULT_BYTE::UInt8 = 0xAA

Base.propertynames(x::AbstractOglBlock) = propertynames(typeof(x))

struct BlockRef{T<:AbstractOglBlock} <: Ref{T}
    block::T
end
Base.Ref(a::AbstractOglBlock) = BlockRef{typeof(a)}(a)
Base.getindex(r::BlockRef) = r.block
Base.unsafe_convert(P::Type{<:Ptr{<:Union{UInt8, Cvoid, T}}}, r::BlockRef{T}) where {T} = begin
    arr = block_byte_array(r.block)
    return Base.unsafe_convert(P, Base.pointer(Ref(arr, 1)))
end

@inline Base.getproperty(a::AbstractOglBlock, name::Symbol) = let Name = Val(name)
    block_property_get(
        a, Name,
        block_property_type(typeof(a), Name)
    )
end
@inline Base.setproperty!(a::AbstractOglBlock, name::Symbol, value) = let Name = Val(name)
    block_property_set(
        a, Name,
        block_property_type(typeof(a), Name),
        value
    )
end

# Equality and hashing:
function Base.:(==)(a::AbstractOglBlock, b::AbstractOglBlock)::Bool
    if block_simple_type(typeof(a)) != block_simple_type(typeof(b))
        return false
    end
    values_a = getproperty.(Ref(a), propertynames(typeof(a)))
    values_b = getproperty.(Ref(b), propertynames(typeof(b)))
    comparisons = values_a .== values_b
    return all(comparisons)
end
Base.hash(a::AbstractOglBlock, h::UInt)::UInt = hash(getproperty.(Ref(a), propertynames(typeof(a))))

function Base.show(io::IO, a::AbstractOglBlock)
    print(io, Base.typename(typeof(a)).name, '(')
    for (i, prop) in enumerate(propertynames(a))
        if i > 1
            print(io, ", ")
        end
        show(io, getproperty(a, prop))
    end
    print(io, ')')
end



#  Block Arrays:  #

# (types defined above out of necessity)

"Returns the array's associated OglBlock type, OglBlock_std140 or OglBlock_std430" penis
block_array_mode(::BlockArray{T, TMode}) where {T, TMode} = TMode

# AbstractVector stuff:
Base.eltype(::BlockArray{T}) where {T} = T
Base.eltype(::Type{<:BlockArray{T}}) where {T} = T
function Base.size(a::BlockArray{T}) where {T}
    stride = block_array_element_stride(T, block_array_mode(a))
    n_bytes = length(block_byte_array(a))
    @bp_gl_assert((n_bytes % stride) == 0, "$n_byte bytes total / $stride")
    n_elements = n_bytes ÷ stride
    return tuple(n_elements)
end
Base.Ref(a::BlockArray{T}, i::Integer = 1) where {T} = Ref(block_byte_array(a), i * block_array_element_stride(T, block_array_mode(a)))
@inline Base.getindex(a::BlockArray, i::Integer) = block_index_get(a, i, eltype(a))
@inline Base.setindex!(a::BlockArray, v, i::Integer) = block_index_set(a, i, eltype(a), v)

"Gets the mutable byte array underlying this array"
block_byte_array(b::BlockArray)::AbstractVector{UInt8} = getfield(b, :buffer)
@inline block_byte_size(x::BlockArray) = length(block_byte_array(x))
block_byte_size(::Type{<:StaticBlockArray{N, T, TMode}}) where {N, T, TMode} = N * block_array_element_stride(T, TMode)

Base.Ref(a::BlockArray, i) = Ref(block_byte_array(a), i)



"Constructs the block-array with an existing byte array"
StaticBlockArray{N, T       }(a::AbstractVector{UInt8}) where {N, T<:AbstractOglBlock} = begin
    byte_stride = block_array_element_stride(T, block_mode(T))
    @bp_check(length(a) ÷ byte_stride == N,
              "Should have provided ", byte_stride * N, " bytes but provided ", length(a))
    StaticBlockArray{N, T, block_mode(T), typeof(a)}(a)
end
StaticBlockArray{N, T, TMode}(a::AbstractVector{UInt8}) where {N, T, TMode           } = begin
    byte_stride = block_array_element_stride(T, TMode)
    @bp_check(length(a) ÷ byte_stride == N,
              "Should have provided ", byte_stride * N, " bytes but provided ", length(a))
    StaticBlockArray{N, T, TMode        , typeof(a)}(a)
end
"Constructs the block-array with an element count"
StaticBlockArray{N, T       }() where {N, T<:AbstractOglBlock} = StaticBlockArray{N, T, block_mode(T), Vector{UInt8}}(fill(BLOCK_DEFAULT_BYTE, block_array_element_stride(T, block_mode(T)) * N))
StaticBlockArray{N, T, TMode}() where {N, T, TMode           } = StaticBlockArray{N, T, TMode        , Vector{UInt8}}(fill(BLOCK_DEFAULT_BYTE, block_array_element_stride(T, TMode        ) * N))


#  Property/element getters and setters:  #

# Block properties each have a type and a byte offset in the larger buffer.
block_property_type(block_type, Name)::Type = error(block_type, " has no property '", val_type(Name), "'")
block_property_first_byte(block_type, Name)::Int = error(block_type, " has no property '", val_type(Name), "'")
# Add helpful error messages for specific cases.
block_property_type(b::AbstractOglBlock, name) = error("You should pass in a type, not an instance")
block_property_type(b, name::Symbol) = error("You should pass in a Val{} for the name, not a Symbol")
block_property_first_byte(b::AbstractOglBlock, name) = error("You should pass in a type, not an instance")
block_property_first_byte(b, name::Symbol) = error("You should pass in a Val{} for the name, not a Symbol")

# Helpers to get the byte range for properties/elements.
function block_property_byte_range(block_type, Name)
    T = block_property_type(block_type, Name)
    b1 = block_property_first_byte(block_type, Name)
    bN = block_field_size(T, block_mode(block_type))
    return b1 : (b1 + bN - 1)
end
function block_array_byte_range(el_type, mode, index)
    bN = block_array_element_stride(el_type, mode)
    b1 = 1 + (bN * (index - 1))
    return b1 : (b1 + bN - 1)
end

# You can get and set the properties of a buffer block.
block_property_get(block, name, TReturn) = error(
    typeof(block), " has no property '",
    val_type(name), "' of type ", TReturn
)
block_property_set(block, name, TReturn, value) = error(
    typeof(block), " has no property '", val_type(name), "' of type ", TReturn,
    ", or it can't be set to a ", typeof(value)
)

# You can get and set elements of a buffer array.
block_index_get(block, i, TReturn) = error(typeof(block), " cannot be indexed to get a ", TReturn)
block_index_set(block, i, TReturn, value) = error(typeof(block), " cannot be indexed to set a ", TReturn, " to a ", typeof(value))


# Normal bitstype getters/setters.
@inline block_property_get(a::AbstractOglBlock, Name::Val, ::Type{TReturn}) where {TReturn} = reinterpret_bytes(
    @view(block_byte_array(a)[block_property_byte_range(typeof(a), Name)]),
    TReturn
)
@inline block_property_set(a::AbstractOglBlock, Name::Val, ::Type{TReturn}, value) where {TReturn} = reinterpret_bytes(
    convert(TReturn, value),
    @view(block_byte_array(a)[block_property_byte_range(typeof(a), Name)])
)
@inline block_index_get(a::BlockArray, i::Integer, ::Type{TReturn}) where {TReturn} = reinterpret_bytes(
    @view(block_byte_array(a)[block_array_byte_range(TReturn, block_array_mode(a), i)]),
    TReturn
)
@inline block_index_set(a::BlockArray, i::Integer, ::Type{TReturn}, value) where {TReturn} = reinterpret_bytes(
    convert(TReturn, value),
    @view(block_byte_array(a)[block_array_byte_range(TReturn, block_array_mode(a), i)])
)

# Bools are stored in a block as UInt32.
@inline block_property_get(a::AbstractOglBlock, Name::Val, ::Type{Bool})::Bool = !iszero(block_property_get(
    a,
    Name,
    UInt32
))
@inline block_property_set(a::AbstractOglBlock, Name::Val, ::Type{Bool}, value) = block_property_set(
    a, Name,
    UInt32, convert(Bool, value) ? one(UInt32) : zero(UInt32)
)
@inline block_index_get(a::BlockArray, i::Integer, ::Type{Bool})::Bool = !iszero(block_index_get(
    a, i, UInt32
))
@inline block_index_set(a::BlockArray, i::Integer, ::Type{Bool}, value) = block_index_set(
    a, i,
    UInt32, convert(Bool, value) ? one(UInt32) : zero(UInt32)
)

# Bool vectors in a block are stored as UInt32 vectors.
@inline block_property_get(a::AbstractOglBlock, Name::Val, ::Type{VecB{N}}) where {N} = map(f->!iszero(f), block_property_get(
    a,
    Name,
    VecU{N}
))
@inline block_property_set(a::AbstractOglBlock, Name::Val, ::Type{VecB{N}}, value) where {N} = block_property_set(
    a, Name,
    UInt32,
    map(f -> convert(Bool, f) ? one(UInt32) : zero(UInt32), value)
)
@inline block_index_get(a::BlockArray, i::Integer, ::Type{VecB{N}}) where {N} = map(f ->!iszero(f), block_index_get(
    a, i, VecU{N}
))
@inline block_index_set(a::BlockArray, i::Integer, ::Type{VecB{N}}, value) where {N} = block_index_set(
    a, i, VecU{N},
    map(f -> convert(Bool, f) ? one(UInt32) : zero(UInt32), value)
)

# Matrix properties are stored in columns, like an array of vectors.
function block_property_get(a::AbstractOglBlock, Name::Val, ::Type{<:Mat{C, R, F}}) where {C, R, F}
    arr = block_property_get(a, Name, StaticBlockArray{C, Vec{R, F}})
    elements_by_column  = Iterators.flatten(arr)
    return @Mat(C, R, F)(elements_by_column...)
end
function block_property_set(a::AbstractOglBlock, Name::Val, ::Type{<:Mat{C, R, F}}, value) where {C, R, F}
    arr = block_property_get(a, Name, StaticBlockArray{C, Vec{R, F}})
    for col in 1:C
        arr[col] = convert(Vec{R, F}, value[:, col])
    end
end
function block_index_get(a::BlockArray, i::Integer, T::Type{<:Mat{C, R, F}}) where {C, R, F}
    a_view = @view block_byte_array(a)[block_array_byte_range(T, block_array_mode(a), i)]
    arr = StaticBlockArray{C, Vec{R, F}, block_array_mode(a)}(a_view)

    column_vectors = Iterators.flatten(arr)
    elements_by_column = Iterators.flatten(column_vectors)
    return @Mat(C, R, F)(elements_by_column...)
end
function block_index_set(a::BlockArray, i::Integer, T::Type{<:Mat{C, R, F}}, value) where {C, R, F}
    a_view = @view block_byte_array(a)[block_array_byte_range(T, block_array_mode(a), i)]
    arr = StaticBlockArray{C, Vec{R, F}, block_array_mode(a)}(a_view)

    for col in 1:C
        arr[col] = convert(Vec{R, F}, value[:, col])
    end
end

# Implementations of getter/setter for a property that is an array:
@inline function block_property_get(a::AbstractOglBlock, Name::Val, ::Type{<:StaticBlockArray{N, T}}
                                   ) where {N, T}
    byte_range = block_property_byte_range(typeof(a), Name)
    arr = @view(block_byte_array(a)[byte_range])
    return StaticBlockArray{N, T, block_mode(a)}(arr)
end
@inline function block_property_set(a::AbstractOglBlock, Name::Val, ::Type{<:StaticBlockArray{N, T}},
                                    values
                                   ) where {N, T}
    @bp_gl_assert(length(values) == N,
                  "Expected to set ", typeof(a), ".", val_type(Name), " to an array of ",
                    N, " elements, but got ", length(values), " elements instead")
    arr = block_property_get(a, Name, StaticBlockArray{N, T})
    # The padding of the input array likely isn't going to line up with the std140 padding,
    #    so we have to set it element-by-element.
    for (i, element) in enumerate(values)
        arr[i] = element
    end
end

# Implementations of getter/setter for a block property:
@inline function block_property_get(a::AbstractOglBlock, Name::Val, T::Type{<:AbstractOglBlock})
    byte_range = block_property_byte_range(typeof(a), Name)
    arr = @view block_byte_array(a)[byte_range]
    return T{typeof(arr)}(arr)
end
@inline function block_property_set(a::AbstractOglBlock, Name::Val, ::Type{T}, value::T) where {T<:AbstractOglBlock}
    byte_range = block_property_byte_range(typeof(a), Name)
    block_byte_array(a)[byte_range] = block_byte_array(value)
end

# Implementations of getter/setter for an array element that's an OglBlock:
@inline function block_index_get(a::StaticBlockArray{N, T}, i::Integer, ::Type{T}) where {N, T<:AbstractOglBlock}
    byte_range = block_array_byte_range(T, block_array_mode(a), i)
    arr = @view block_byte_array(a)[byte_range]
    return T{typeof(arr)}(arr)
end
@inline function block_index_set(a::StaticBlockArray{N, T}, i::Integer, ::Type{T}, value::T) where {N, T<:AbstractOglBlock}
    b1 = 1 + (i * block_byte_size(T))
    bN = block_byte_size(T)
    bEnd = b1 + bN - 1
    block_byte_range = block_array_byte_range(T, block_array_mode(a), i)
    block_byte_array(a)[block_byte_range] = block_byte_array(value)
end


#  OpenGL Spec implementation  #

block_field_alignment()::Int = error("Unimplemented")
block_field_size()::Int = error("Unimplemented")

block_array_element_alignment()::Int = error("Unimplemented")
block_array_element_stride()::Int = error("Unimplemented")


block_field_alignment(T::Type{<:AbstractOglBlock}, mode::Type{<:AbstractOglBlock}) = block_alignment(T)
# Most scalars/vectors translate to the GPU trivially.
# However bools are 4 bytes.
block_field_alignment(T::Type{<:ScalarBits}                , mode::Type{<:AbstractOglBlock}) = sizeof(T)
block_field_alignment( ::Type{Bool}                        , mode::Type{<:AbstractOglBlock}) = sizeof(UInt32)
block_field_alignment( ::Type{Vec{N, T}}                   , mode::Type{<:AbstractOglBlock}) where {N, T} =
    if N == 3
        block_field_alignment(Vec{4, T}, mode)
    elseif T == Bool
        block_field_alignment(Vec{N, UInt32}, mode)
    else
        N * sizeof(T)
    end
# AbstractOglBlock's are already sized appropriately.
# Array fields are based on their elements.
block_field_alignment( ::Type{<:StaticBlockArray{N, T}}    , mode::Type{<:AbstractOglBlock}) where {N, T} = block_array_element_alignment(T, mode)
# Matrices are like an array of column vectors.
block_field_alignment( ::Type{<:Mat{C, R, F}}              , mode::Type{<:AbstractOglBlock}) where {C, R, F} =
    block_field_alignment(StaticBlockArray{C, Vec{R, F}, mode}, mode)

block_field_size(T::Type                          , mode::Type{<:AbstractOglBlock})                 = block_field_alignment(T, mode)
block_field_size( ::Type{<:Vec{N, T}}             , mode::Type{<:AbstractOglBlock}) where {N, T}    = N * sizeof((T == Bool) ? UInt32 : T)
block_field_size(T::Type{<:AbstractOglBlock}      , mode::Type{<:AbstractOglBlock})                 = block_byte_size(T)
block_field_size( ::Type{<:Mat{C, R, F}}          , mode::Type{<:AbstractOglBlock}) where {C, R, F} = block_field_size(StaticBlockArray{C, Vec{R, F}, mode}, mode)
block_field_size( ::Type{<:StaticBlockArray{N, T}}, mode::Type{<:AbstractOglBlock}) where {N, T   } = N * block_array_element_stride(T, mode)

# An array element's alignment is equal to its alignment as a field,
#    if in std140 then rounded up to a multiple of v4f.
block_array_element_alignment(T, mode)                        = block_field_alignment(T, mode)
block_array_element_alignment(T, mode::Type{OglBlock_std140}) = round_up_to_multiple(block_field_alignment(T, mode), sizeof(v4f))

block_array_element_stride(T                               , mode)              = block_array_element_alignment(T, mode)
block_array_element_stride(T::Type{<:AbstractOglBlock}     , mode)              = block_byte_size(T)
block_array_element_stride(T::Type{<:Mat{C}}               , mode) where {C}    = C * block_array_element_alignment(T, mode)
block_array_element_stride( ::Type{StaticBlockArray{N, T}} , mode) where {N, T} = N * block_array_element_stride(T, mode)


#= A new block struct (call it `s::S`) must implement the following:
    * Base.propertynames(::Type{<:S})
    * block_property_types(::Type{<:S})
    * block_simple_type(::Type{<:S}) = S
    * block_byte_size(::Type{<:S})
    * block_padding_size(::Type{<:S})
    * block_alignment(::Type{<:S})
    * Per property:
        * block_property_type(::Type{<:S}, ::Val)::Type
        * block_property_first_byte(::Type{<:S}, ::Val)
    * Internal constructor that takes an `AbstractVector{UInt8}`
    * External constructor that takes all the fields and uses a `Vector{UInt8}` buffer initially filled with BLOCK_DEFAULT_BYTE
=#

"Set this global to print generated buffer structs to the stream"
BUFFER_LAYOUT_MACRO_DEBUG_STREAM::Optional{IO} = nothing


#TODO: Support some kind of annotation for row-major matrices.
"""
Generates a struct of OpenGL data,
    whose byte layout exactly follows the std140 standard in shader blocks.

The struct is backed by a mutable byte array, so you can get *and set* its properties.
You can also nest `@std140` structs within each other and they will be laid out as the GPU expects.

Sample usage:
````
@std140 struct MyInnerUniformBlock
    f::Float32
    bools::vb4
    position_array::StaticBlockArray{12, v3f}
end

@std140 struct MyOuterUniformBlock
    i::Int32 # Be careful; 'Int' in Julia means Int64
    items::StaticBlockArray{5, MyInnerUniformBlock}
    b::Bool
end

const MY_UBO_DATA = MyOuterUniformBlock(
    3,
    ntuple(i -> zero(MyInnerUniformBlock), 5),
    true
)
println("MyOuterUniformBlock takes up ", length(block_byte_array(MY_UBO_DATA)), " bytes, ",
          block_padding_size(MY_UBO_DATA), " of which is padding")
println("i is ", MY_UBO_DATA.i)

MY_UBO_DATA.i = 1122334455
println("Now i is ", MY_UBO_DATA.i)

# Upload the data to your GPU buffer:
set_buffer_data(my_ubo, MY_UBO_DATA)

# Download the data from your GPU buffer into a new or existing instance of the struct:
my_ubo_data = get_buffer_data(my_ubo, MyOuterUniformBlock)
get_buffer_data(my_second_ubo, my_ubo_data)
````
"""
macro std140(struct_expr)
    return block_struct_impl(struct_expr, OglBlock_std140, __module__)
end
"""
Generates a struct of OpenGL data,
    whose byte layout exactly follows the std430 standard in shader blocks.

The struct is backed by a mutable byte array, so you can get *and set* its properties.
You can also nest `@std430` structs within each other and they will be laid out as the GPU expects.

Sample usage:
````
@std140 struct MyInnerUniformBlock
    f::Float32
    bools::vb4
    position_array::StaticBlockArray{12, v3f}
end

@std430 struct MyOuterShaderStorageBlock
    i::Int32 # Be careful; 'Int' in Julia means Int64
    items::StaticBlockArray{5, MyInnerShaderStorageBlock}
    b::Bool
end

const MY_SSBO_DATA = MyOuterShaderStorageBlock(
    3,
    ntuple(i -> zero(MyInnerShaderStorageBlock), 5),
    true
)
println("MyOuterShaderStorageBlock takes up ", length(block_byte_array(MY_SSBO_DATA)), " bytes, ",
          block_padding_size(MY_SSBO_DATA), " of which is padding")
println("i is ", MY_SSBO_DATA.i)

MY_SSBO_DATA.i = 1122334455
println("Now i is ", MY_SSBO_DATA.i)

# Upload the data to your GPU buffer:
set_buffer_data(my_ssbo, MY_SSBO_DATA)

# Download the data from your GPU buffer into a new or existing instance of the struct:
my_ssbo_data = get_buffer_data(my_ssbo, MyOuterShaderStorageBlock)
get_buffer_data(my_second_ssbo, my_ssbo_data)
````
"""
macro std430(struct_expr)
    return block_struct_impl(struct_expr, OglBlock_std430, __module__)
end
function block_struct_impl(struct_expr, mode::Type{<:AbstractOglBlock}, invoking_module::Module)
    if !Base.is_expr(struct_expr, :struct)
        error("Expected struct block, got: ", struct_expr)
    elseif struct_expr.args[1]
        error("UBO struct cannot be mutable; wrap it in a Ref if you want that!")
    end

    mode_switch(std140, std430) = if mode == OglBlock_std140
                                      std140()
                                  elseif mode == OglBlock_std430
                                      std430()
                                  else
                                      error("Unexpected mode: ", mode)
                                  end
    base_type::Type{<:AbstractOglBlock} = mode
    mode_description = mode_switch(() -> :std140,
                                   () -> :std430)

    SCALAR_TYPE = Union{Scalar32, Scalar64, Bool}
    VECTOR_TYPE = Union{(
        Vec{n, t}
          for (n, t) in Iterators.product(1:4, union_types(SCALAR_TYPE))
    )...}
    MATRIX_TYPE = Union{(
        @Mat(c, r, f)
          for (c, r, f) in Iterators.product(1:4, 1:4, (Float32, Float64))
    )...}
    NON_ARRAY_TYPE = Union{SCALAR_TYPE, VECTOR_TYPE, MATRIX_TYPE, base_type}
    ARRAY_TYPE = StaticBlockArray{N, <:NON_ARRAY_TYPE} where {N}

    # Parse the header.
    (is_mutable_from_cpu::Bool, struct_name, body::Expr) = struct_expr.args
    if !isa(struct_name, Symbol)
        error(mode_description, " struct has invalid name: '", struct_name, "'")
    elseif is_mutable_from_cpu
        @warn "You declared $struct_name as mutable, which is non-standard syntax and does not change anything"
    end

    # Parse the body.
    lines = [line for line in body.args if !isa(line, LineNumberNode)]
    function check_field_errors(field_name, T, is_within_array::Bool = false)
        if T <: Vec
            if !(T <: VECTOR_TYPE)
                error("Invalid vector count or type in ", field_name, ": ", T)
            end
        elseif T <: Mat
            if !(T <: MATRIX_TYPE)
                error("Invalid matrix size or component type in ", field_name, ": ", T)
            end
        elseif T <: StaticBlockArray
            if is_within_array
                error("No nested arrays allowed, for simplicity. Flatten field ", field_name)
            end
            check_field_errors(field_name, eltype(T), true)
        elseif isstructtype(T)
            if !(T <: base_type)
                error("Non-", mode_description, " struct referenced by ", field_name, ": ", T)
            end
        elseif T <: SCALAR_TYPE
            # Nothing to check
        else
            error("Unexpected type in field ", struct_name, ".", field_name, ": ", T)
        end
    end
    field_definitions = map(lines) do line
        if !Base.is_expr(line, :(::))
            error("Expected only field declarations ('a::B'). Got: ", line)
        end

        (field_name, field_type) = line.args
        if !isa(field_name, Symbol)
            error("Name of the field should be a simple token. Got: '", field_name, "'")
        end

        field_type = invoking_module.eval(field_type)
        if !isa(field_type, Type)
            error("Expected a concrete type for the field's value. Got ", field_type)
        end
        check_field_errors(field_name, field_type)

        return (field_name, field_type)
    end

    # Figure out padding and field offsets.
    total_byte_size::Int = 0
    total_padding_bytes::Int = 0
    max_field_alignment::Int = 0
    property_offsets = Vector{Int}()
    function align_to(alignment)
        max_field_alignment = max(max_field_alignment, alignment)

        missing_bytes = (alignment - (total_byte_size % alignment))
        if missing_bytes < alignment # Only if not already aligned
            total_byte_size += missing_bytes
            total_padding_bytes += missing_bytes
        end
    end
    for (field_name, field_type) in field_definitions
        field_alignment = block_field_alignment(field_type, mode)
        field_size = block_field_size(field_type, mode)

        # Insert padding bytes to align the field.
        align_to(field_alignment)

        # Insert the field's own bytes.
        push!(property_offsets, total_byte_size)
        total_byte_size += block_field_size(field_type, mode)
    end

    # Struct alignment is based on the largest alignment of its fields.
    struct_alignment = mode_switch(
        () -> round_up_to_multiple(max_field_alignment, sizeof(v4f)),
        () -> max_field_alignment
    )
    # Add padding to the struct to match its alignment.
    # Note that this inadvertently modifies 'max_field_alignment',
    #    but that variable isn't used past this point.
    align_to(struct_alignment)
    max_field_alignment = -1

    # Generate the functions that need generating.
    struct_name_esc = esc(struct_name)
    struct_type_esc = :( Type{<:$struct_name_esc} )
    output = quote
        Core.@__doc__ struct $struct_name_esc{Buffer<:AbstractVector{UInt8}} <: $mode
            $(BUFFER_FIELD_NAME)::Buffer

            $struct_name_esc() = new{Vector{UInt8}}(fill(
                $BLOCK_DEFAULT_BYTE,
                $(@__MODULE__).block_byte_size($struct_name_esc)
            ))
            $struct_name_esc{TArray}(buffer::TArray) where {TArray<:AbstractVector{UInt8}} = new{TArray}(buffer)
        end
        $(@__MODULE__).block_simple_type(::$struct_type_esc) = $struct_name_esc

        # Constructor that takes field values:
        if $(!isempty(field_definitions))
            function $struct_name_esc($((esc(n) for (n, t) in field_definitions)...))
                s = $struct_name_esc{Vector{UInt8}}(fill(BLOCK_DEFAULT_BYTE, block_byte_size($struct_name_esc)))
                # Set each property to its corresponding constructor parameter.
                $((map(field_definitions) do (n,t); :(
                    s.$n = $(esc(n))
                ) end)...)
                return s
            end
        end

        # Provide metadata.
        $(@__MODULE__).block_byte_size(::$struct_type_esc) = $total_byte_size
        $(@__MODULE__).block_padding_size(::$struct_type_esc) = $total_padding_bytes
        $(@__MODULE__).block_alignment(::$struct_type_esc) = $struct_alignment

        # Advertise this type's properties.
        $Base.propertynames(::$struct_type_esc) = $(Tuple(
            n for (n, t) in field_definitions
        ))
        $(@__MODULE__).block_property_types(::$struct_type_esc) = tuple($((
            t for (n, t) in field_definitions
        )...))
        $((map(zip(field_definitions, property_offsets)) do ((field_name, field_type), field_offset)
            name_val_expr = :( Val{$(QuoteNode(field_name))} )
            quote
                $(@__MODULE__).block_property_type(      ::$struct_type_esc, ::$name_val_expr) = $field_type
                $(@__MODULE__).block_property_first_byte(::$struct_type_esc, ::$name_val_expr) = $field_offset + 1
            end
        end)...)
    end
    if exists(BUFFER_LAYOUT_MACRO_DEBUG_STREAM)
        println(BUFFER_LAYOUT_MACRO_DEBUG_STREAM,
                 "@", mode_description, "(", struct_name, "):",
                 "\n", output)
    end
    return output
end

export @std140, @std430