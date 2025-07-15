##########################################################################################################################
##################################################### UTILITIES ##########################################################
##########################################################################################################################

export @crate

const Container{T, N} = Union{AbstractVector{T}, NTuple{N, T}}
const JOIN_SYMBOL = '|'

macro crate(expr,args...)
    app = CruiseApp()
	path_data = split(expr.args[1], JOIN_SYMBOL)
    path = joinpath(path_data...)
    T = expr.args[2]

    return :(Load!($app.manager, $T, $path, ($args)...))
end