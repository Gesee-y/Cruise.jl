"""
A contiguous block of memory on the GPU,
   for storing any kind of data.
Most commonly used to store mesh vertices/indices, or other arrays of things.

To initialize, you can provide its byte-size or some data to upload
    (which passes through `buffer_data_convert()`).
For help with uploading a whole data structure to a buffer, see `@std140` and `@std430`.

UNIMPLEMENTED: Instances can be "mapped" to the CPU, allowing you to write/read them directly
   as if they were a plain C array.
This is often more efficient than setting the buffer data the usual way,
   e.x. you could read the mesh data from disk directly into this mapped memory.
"""
mutable struct Buffer <: AbstractResource
    handle::Ptr_Buffer
    byte_size::UInt64
    is_mutable_from_cpu::Bool

    "Create a buffer of the given size, with uninitialized data"
    function Buffer( byte_size::Integer, can_change_data_from_cpu::Bool,
                     recommend_storage_on_cpu::Bool = false
                   )::Buffer
        b = new(Ptr_Buffer(), 0, false)
        set_up_buffer(
            byte_size, can_change_data_from_cpu,
            nothing,
            recommend_storage_on_cpu,
            b
        )
        return b
    end
    "Create a buffer big enough to hold N copies of the given bitstype"
    function Buffer( can_change_data_from_cpu::Bool,
                     T::Type, count::Integer = 1
                     ; recommend_storage_on_cpu::Bool = false)
        @bp_check(isbitstype(T),
                  T, " isn't a bitstype")
        return Buffer(sizeof(T) * count, can_change_data_from_cpu,
                      recommend_storage_on_cpu)
    end

    "Create a buffer containing your data, given as a pointer and byte-size"
    function Buffer( can_change_data_from_cpu::Bool,
                     ref_and_size::Tuple{<:Ref, <:Integer},
                     ;
                     recommend_storage_on_cpu::Bool = false,
                   )::Buffer
        b = new(Ptr_Buffer(), 0, false)
        set_up_buffer(
            ref_and_size[2],
            can_change_data_from_cpu,
            ref_and_size[1],
            recommend_storage_on_cpu,
            b
        )
        return b
    end
    "Create a buffer containing your data, as an instance of some bits-type"
    function Buffer(can_change_data_from_cpu::Bool,
                    initial_bits_data
                    ;
                    recommend_storage_on_cpu::Bool = false)
        @bp_check(isbits(initial_bits_data),
                  typeof(initial_bits_data), " isn't a bitstype")
        @bp_check(!isa(initial_bits_data, Bool),
                  "You probably meant to invoke the other overload of Buffer()")

        return Buffer(can_change_data_from_cpu,
                      (Ref(initial_bits_data), sizeof(initial_bits_data))
                      ;
                      recommend_storage_on_cpu=recommend_storage_on_cpu)
    end
    "Create a buffer containing your data, as an array of some data"
    function Buffer(can_change_data_from_cpu::Bool,
                    data_array::AbstractArray
                    ;
                    recommend_storage_on_cpu::Bool = false)
        @bp_check(isbitstype(eltype(data_array)),
                  eltype(data_array), " isn't a bitstype")
        if data_array isa SubArray
            @bp_check(Base.iscontiguous(data_array),
                      "Array view isn't contiguous so it can't be uploaded to the GPU")
        end
        return Buffer(can_change_data_from_cpu,
                      (Ref(data_array, 1),
                       sizeof(eltype(data_array)) * length(data_array))
                      ; recommend_storage_on_cpu=recommend_storage_on_cpu)
    end
end


@inline function set_up_buffer( byte_size::I, can_change_data_from_cpu::Bool,
                                initial_byte_data::Optional{Ref},
                                recommend_storage_on_cpu::Bool,
                                output::Buffer
                              ) where {I<:Integer}
    @bp_check(exists(get_context()), "No B+ GL.Context to create this buffer in")
    handle::Ptr_Buffer = Ptr_Buffer(get_from_ogl(gl_type(Ptr_Buffer), glCreateBuffers, 1))

    flags::GLbitfield = 0
    if recommend_storage_on_cpu
        flags |= GL_CLIENT_STORAGE_BIT
    end
    if can_change_data_from_cpu
        flags |= GL_DYNAMIC_STORAGE_BIT
    end

    setfield!(output, :handle, handle)
    setfield!(output, :byte_size, UInt64(byte_size))
    setfield!(output, :is_mutable_from_cpu, can_change_data_from_cpu)

    glNamedBufferStorage(handle, byte_size,
                         exists(initial_byte_data) ?
                             initial_byte_data :
                             C_NULL,
                         flags)
end

Base.show(io::IO, b::Buffer) = print(io,
    "Buffer<",
    Base.format_bytes(b.byte_size),
    (b.is_mutable_from_cpu ? " Mutable" : ""),
    " ", b.handle,
    ">"
)

function Base.close(b::Buffer)
    h = b.handle
    glDeleteBuffers(1, Ref{GLuint}(b.handle))
    setfield!(b, :handle, Ptr_Buffer())
end

export Buffer


#########################
#       Buffer Set      #
#########################

"Updates a buffer's data with a given pointer and destination byte range"
function set_buffer_data(b::Buffer, data::Ref,
                         buffer_byte_range::Interval{<:Integer} = IntervalU(
                             min=1,
                             size=b.byte_size
                         ))
    @bp_check(b.is_mutable_from_cpu, "Buffer is immutable")
    @bp_check(min_inclusive(buffer_byte_range) > 0,
              "Buffer byte range starts behind the first byte! ", buffer_byte_range)
    @bp_check(max_inclusive(buffer_byte_range) <= b.byte_size,
              "Buffer byte range ends before the last byte! ", buffer_byte_range)
    glNamedBufferSubData(
        b.handle,
        min_inclusive(buffer_byte_range) - 1,
        size(buffer_byte_range),
        data
    )
    return nothing
end

"Sets a buffer's data with an array and destination byte range"
function set_buffer_data(b::Buffer, data::AbstractArray, buffer_first_byte::Integer = 1)
    T = eltype(data)
    @bp_check(isbitstype(T), "Can't upload an array of non-bitstype '$T' to a GPU Buffer")

    set_buffer_data(b, Ref(data, 1),
                    IntervalU(min=buffer_first_byte,
                              size=length(data)*sizeof(T)))
end

"Sets a buffer's data to a given bitstype data"
@inline function set_buffer_data(b::Buffer, bits_data, buffer_first_byte::Integer = 1)
    @bp_check(isbits(bits_data),
              typeof(bits_data), " isn't a bitstype")
    set_buffer_data(b, Ref(bits_data),
                    IntervalU(min=buffer_first_byte,
                              size=sizeof(bits_data)))
end

# Vec is bitstype, but also AbstractArray. It should be treated as the former.
set_buffer_data(b::Buffer, v::Vec, buffer_first_byte::Integer = 1) = set_buffer_data(b, v.data, buffer_first_byte)

export set_buffer_data


#########################
#      Buffer Copy      #
#########################


"
Copies data from one buffer to another.
By default, copies as much data as possible.
"
function copy_buffer( src::Buffer, dest::Buffer
                      ;
                      src_byte_offset::UInt = 0x0,
                      dest_byte_offset::UInt = 0x0,
                      byte_size::UInt = min(src.byte_size - src.byte_offset,
                                            dest.byte_size - dest.byte_offset)
                    )
    @bp_check(src_byte_offset + byte_size <= src.byte_size,
              "Going outside the bounds of the 'src' buffer in a copy:",
                " from ", src_byte_offset, " to ", src_byte_offset + byte_size)
    @bp_check(dest_byte_offset + byte_size <= dest.byte_size,
              "Going outside the bounds of the 'dest' buffer in a copy:",
                " from ", dest_byte_offset, " to ", dest_byte_offset + byte_size)
    @bp_check(dest.is_mutable_from_cpu, "Destination buffer is immutable")

    glCopyNamedBufferSubData(src.handle, dest.handle,
                             src_byte_offset,
                             dest_byte_offset,
                             byte_size)
end

export copy_buffer


#########################
#       Buffer Get      #
#########################

"
Gets a buffer's data and writes it to the given pointer.
Optionally uses a subset of the buffer's bytes.
"
function get_buffer_data(b::Buffer, output::Ref,
                         buffer_byte_range::Interval{<:Integer} = IntervalU(
                             min=1,
                             size=b.byte_size
                         ))::Nothing
    @bp_check(min_inclusive(buffer_byte_range) > 0,
              "Buffer byte range passes behind the start of the buffer: ", buffer_byte_range)
    @bp_check(max_inclusive(buffer_byte_range) <= b.byte_size,
              "Buffer byte range passes beyond the end of the buffer ",
                "(size ", b.byte_size, ") ",
                "(range ", min_inclusive(buffer_byte_range), " - ", max_inclusive(buffer_byte_range), ")")
    glGetNamedBufferSubData(
        b.handle,
        min_inclusive(buffer_byte_range) - 1,
        size(buffer_byte_range),
        output
    )
end

"Gets a buffer's data and returns it as an instance of the given bits-type"
function get_buffer_data(b::Buffer, ::Type{T},
                         buffer_first_byte::Integer = 1
                        )::T where {T}
    @bp_check(isbitstype(T),   T, " isn't a bitstype")
    let r = Ref{T}()
        get_buffer_data(b, r,
                        IntervalU(min=buffer_first_byte, size=sizeof(T)))
        return r[]
    end
end

"Gets a buffer's data and writes it into the given array of bitstypes"
function get_buffer_data(b::Buffer, a::AbstractArray{T},
                         buffer_first_byte::Integer = 1
                        )::Nothing where {T}
    @bp_check(!isbitstype(a),  typeof(a), " doesn't appear to be a mutable array")
        # Note that we can't use ismutable() because some immutable structs hold a reference to mutable data
    @bp_check(isbitstype(T),   T, " isn't a bitstype")
    if a isa SubArray
        @bp_check(Base.iscontiguous(a),
                  "Array view isn't contiguous so it can't be uploaded to the GPU")
    end

    get_buffer_data(b, Ref(a, 1),
                    IntervalU(min=buffer_first_byte,
                              size=sizeof(T)*length(a)))
    return nothing
end

"Gets a buffer's data and returns it as an array of the given count (per-axis) and bits-type"
function get_buffer_data(b::Buffer, output::Tuple{Type, Vararg{Integer}},
                         buffer_first_byte::Integer = 1)::Vector{output[1]}
    (T, vec_size...) = output
    @bp_check(isbitstype(T),   T, "isn't a bitstype")

    Dimensions = length(vec_size)
    @bp_check(Dimensions > 0,
              "Must provide at least one axis for the output array; provided ",
                vec_size)

    arr = Array{T, Dimensions}(undef, vec_size)
    get_buffer_data(b, arr, buffer_first_byte)
    return arr
end

export get_buffer_data