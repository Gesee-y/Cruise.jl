#########################################################################################################################
##################################################### COMPONENT #########################################################
#########################################################################################################################

###################################################### Exports ##########################################################

export @component
export to_symbol

###################################################### Core ######################################################

"""
    @component name begin
        field1
        field2
          .
          .
          .
        fieldn
    end

This macro create a new component for you. It's possible to do it manually but there is no real gains.
"""
macro component(name, block)
	struct_name = Symbol(string(name)*_default_suffix())
	ex = string(name) # Just to interpolate a symbol

	# We add the dirty field
	#pushfirst!(block.args, :($DIRTY_FIELD::Bool))
	
	## We add the constructor
	push!(block.args, :($struct_name(args...) = new(args...)))

	# Our struct expression
	struct_ex = Expr(:struct, false, :($struct_name <: AbstractComponent), block)
	__module__.eval(struct_ex)

    __module__.eval(quote
			ReactiveECS.to_symbol(::Type{$struct_name}) = Symbol($ex)

			for field in fieldnames($struct_name)
				T = $struct_name
				f = QuoteNode(field)
				type = fieldtype($struct_name, field)
				ReactiveECS.eval(:(get_field(st::TableColumn{$T},
					::Val{$f})::Vector{$type} = getproperty(getfield(st, :data), ($f))
				))
		    end
        end
    )
end

to_symbol(T::Type{<:AbstractComponent}) = error("to_symbol not defined for type $T.")
to_symbol(s::Symbol) = s
to_symbol(c::T) where T <: AbstractComponent = to_symbol(T)

"""
    get_bits(table::ArchTable{T}, s::Symbol)

This function return the bit signature of a component. A component just represent one bit 
"""
get_bits(table::ArchTable{T}, s::Symbol) where T <: Integer = T(get_id(table.columns[s]))
get_bits(table::ArchTable, ss) = 0
function get_bits(table::ArchTable, ss::Tuple)
    
	# We initialize our result
	v = UInt128(0)

	# Then we just add the other bit vector
	for s in ss
		bit_pos = get_bits(table, s)
		v |= 1 << bit_pos
	end

	return v
end
get_bits(n::Integer) = UInt128(n)


_default_suffix() = ""