struct UnionArray{T, N, P} <: Abstract.UnionArray{T, N}
    parent::P

    function UnionArray(parent::P) where {T, N, P <: AbstractArray{T, N}}
        # Make sure that `A.parent` is not a UnionArray/Vector
        P <: UnionArrayImpls && throw(MethodError(UnionArray, (A,)))
        return new{T, N, P}(parent)
    end
end

const UnionArrayImpls = Union{UnionVector, UnionArray}

default_reshape(A::UnionVector, dims::T) where T =
    invoke(reshape, Tuple{AbstractArray, T}, A, dims)

ua_reshape(A::UnionVector, dims) = UnionArray(default_reshape(A, dims))
ua_reshape(A::UnionArray, dims) = UnionArray(reshape(A.parent, dims))
ua_reshape(A::UnionVector, ::Tuple{Colon}) = A
function ua_reshape(A::UnionArray, ::Tuple{Colon})
    v = reshape(A.parent, :)
    if v isa UnionVector
        return v
    else
        return UnionArray(v)
    end
end

Base.reshape(A::UnionArrayImpls, dims::Dims) =
    ua_reshape(A, dims) :: UnionArrayImpls
Base.reshape(A::UnionArrayImpls, dims::Tuple{Vararg{Union{Int,Colon}}}) =
    ua_reshape(A, dims) :: UnionArrayImpls

Base.parent(A::UnionArray) = A.parent
Base.size(A::UnionArray) = size(A.parent)
Base.getindex(A::UnionArray, I...) = A.parent[I...]
Base.setindex!(A::UnionArray, v, I...) = setindex!(A.parent, v, I...)

# Base.showarg(io::IO, A::UnionArray, toplevel) =
#     Base.showarg(io, A.parent, toplevel)
