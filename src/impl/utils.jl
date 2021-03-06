TypeTuple{N} = NTuple{N, Type}

astupleoftypes(x::TypeTuple) = x
astupleoftypes(::Type{T}) where {T <: Tuple} = Tuple(T.parameters)

@inline foldlargs(op, x) = x
@inline foldlargs(op, x1, x2, xs...) =
    foldlargs(op,
              @return_if_reduced(op(x1, x2)),
              xs...)

@inline foldltupletype(op, T, ::Type{<:Tuple{}}) = T
@inline foldltupletype(op, T, ::Type{S}) where {S <: Tuple} =
    foldltupletype(op,
                   @return_if_reduced(op(T, Base.tuple_type_head(S))),
		   Base.tuple_type_tail(S))

@inline foldltupletype(op, ::Type{T}, ::Type{<:Tuple{}}) where T = T
@inline foldltupletype(op, ::Type{T}, ::Type{S}) where {T, S <: Tuple} =
    foldltupletype(op,
                   @return_if_reduced(op(T, Base.tuple_type_head(S))),
		   Base.tuple_type_tail(S))

asunion(T::Type{<:Tuple}) = foldltupletype((T, s) -> Union{T, s}, Union{}, T)


struct Padded{T, N}
    value::T
    pad::NTuple{N, UInt8}
end

Padded{T, N}(value::T) where {T, N} = Padded(value, zeropad(N))
zeropad(N) = ntuple(_ -> UInt8(0), N)
addpadding(N::Integer, ::Type{T}) where T = Padded{T, N}
addpadding(N::Integer, value::T) where T = Padded{T, N}(value)

Base.convert(::Type{P}, x::T) where {T, P <: Padded{T}} = P(x)

unpad(x) = x
unpad(x::Padded) = x.value
unpad(::Type{<:Padded{T}}) where T = T

paddedtype(::T) where T = paddedtype(T)
paddedtype(::Type{<:Padded{T}}) where T = T
paddedtype(::Type{T}) where T = T

# not sure relying on `sizeof` is safe; so:
sizeoftype(::Type{T}) where T = sizeof(T)
sizeoftype(::T) where T = sizeof(T)

ofsamesize(bigger::Type, smaller) =
    if sizeof(bigger) < sizeoftype(smaller)
        error("Target type is not big enough")
    elseif sizeof(bigger) == sizeoftype(smaller)
        smaller
    else
        addpadding(sizeof(bigger) - sizeoftype(smaller), smaller)
    end
