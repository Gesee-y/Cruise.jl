## Broadcasting of static arrays ##

Base.iterate(A::AbstractSArray,i::Int=1) = i > length(A) ? nothing : (A[i],i+1)

#Base.broadcastable(A::AbstractSArray) = Tuple(A)
Base.BroadcastStyle(::Type{<:AbstractSArray{T,D,N}}) where {T,D,N} = Broadcast.ArrayStyle{AbstractSArray{T,D,N}}()

Base.similar(::Type{SArray{T, D, N} where {N, D<:Tuple}}, shape::Tuple{Union{Integer, Base.OneTo}, 
			Vararg{Union{Integer, Base.OneTo}}}) where T = begin
	
	NewD = Base.to_shape(shape)
	SArray{T,Tuple{NewD...},length(NewD),prod(NewD)}(undef)
end
Base.similar(::Type{iSArray{T, D, N} where {N, D<:Tuple}}, shape::Tuple{Union{Integer, Base.OneTo}, 
			Vararg{Union{Integer, Base.OneTo}}}) where T = begin
	
	NewD = Base.to_shape(shape)
	iSArray{T,Tuple{NewD...},length(NewD),prod(NewD)}(undef)
end

Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbstractSArray{T,D,N}}}, ::Type{ElType},::NTuple{N,Base.OneTo{Int64}}) where {ElType,T,D,N} = begin
    similar(SArray{ElType}, axes(bc))
end