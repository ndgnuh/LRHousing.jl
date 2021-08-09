### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 0ffc59b2-f8f7-11eb-1d41-d7be3a660bff
begin
	using Pkg
	Pkg.activate(joinpath(@__DIR__, ".."))
end

# ╔═╡ f601a1f4-0da2-457a-8276-97801af40c82
begin
	using LRHousing
	using CategoricalArrays
end

# ╔═╡ 2df81d5b-72e2-44b7-b84b-b1cb43bb05b5
using StatsBase

# ╔═╡ add411c5-4026-4c9c-92a3-e7181ccd6467
using DataFrames

# ╔═╡ 1bcda19e-3bac-48cb-a550-f23a76e72cf2
using Chain: @chain

# ╔═╡ 4049eb62-6ffa-427b-8a35-7f8b67e51f70
train = LRHousing.read_data("../data/train.csv")

# ╔═╡ 24af9da5-8615-4c36-b5df-e10409ca008a
pl = LRHousing.DataPipeline(train; ignore=["Id"])

# ╔═╡ b06fbcf9-6f2b-412e-aaea-3497fae925c3
trainp = select(pl(train), Not(pl.ignore))

# ╔═╡ f7aa44b0-a3c0-470a-a1d6-1274d80ca67e
describe(train)

# ╔═╡ 0fb1ac77-1d12-4ebf-91e1-983bc925d86d
function number_binning(X, k=10)
	minx = minimum(X)
	maxx = maximum(X)
	bins = range(start=minx, stop=maxx, length=k)
	map(x -> findfirst(x .< bins), X)
end

# ╔═╡ e8dd05ec-b8ce-4c84-b613-6fa38b4f0fb0
number_binning(trainp.GrLivArea)

# ╔═╡ 36dc88cc-dbf2-487b-b24a-494c4722ad32
begin
	function crammerv(x::CategoricalArray, y::CategoricalArray)
		@assert length(x) == length(y)
		lx = levelcode.(x)
		ly = levelcode.(y)
		cx = countmap(lx)
		cy = countmap(ly)
		ux = unique(lx)
		uy = unique(ly)
		k = length(unique(x))
		r = length(unique(y))
		cxy = countmap(zip(lx, ly))
		n = length(x)
		chisq = sum(begin
				nume = (get(cxy, (i, j), 0) - cx[i] * cy[j] / n)^2
				deno = (cx[i] * cy[j] / n)
				nume / deno
			end for (i, j) in Iterators.product(ux, uy))
		sqrt(chisq / n / min(k - 1, r - 1))
	end
	crammerv(x::CategoricalArray, y) = crammerv(x, number_binning(y, 10))
	crammerv(x, y::CategoricalArray) = crammerv(number_binning(x, 10), y)
end

# ╔═╡ 37c0a640-bda7-4e25-916c-ef182de83fc9
crammerv(categorical(train.MSZoning), train.LotShape |> categorical)

# ╔═╡ a0ba3080-b1ce-4c63-8480-28594c4a69de
crammerv(trainp.BldgType, trainp.BldgType)

# ╔═╡ f025061b-99ac-4663-a104-30bb9def46ba
function cor_matrix(df)
	result = DataFrame(col=names(df))
	function compute_cor(name_1, name_2)
		col_1 = df[!, name_1]
		col_2 = df[!, name_2]
		if eltype(col_1) <: Number && eltype(col_2) <: Number
			StatsBase.cor(col_1, col_2)
		else
			crammerv(categorical(col_1), categorical(col_2))
		end
	end
	transformations = map(names(df)) do name_1
		:col => ByRow(name_2 -> compute_cor(name_1, name_2)) => Symbol(name_1)
	end
	transformations
	transform(result, transformations...)
end

# ╔═╡ f7643ebf-da43-42fb-bd75-d204b54d0b08
eltype(trainp.MSSubClass) <: Number

# ╔═╡ 7c52649d-77a0-4fda-991f-89ea0ade4211
cordf = cor_matrix(trainp)

# ╔═╡ 4dbe4a01-bbc3-4274-9ca0-03e0a903d1e1
function find_multicolinearity(cordf, ycol; threshold=0.8)
	to_be_removed = String[]
	sizehint!(to_be_removed, size(cordf, 1)÷3)
	considers = setdiff(cordf.col, ["SalePrice"])
	name_index = String.(cordf.col)
	df = select(cordf, Not("col"))
	map(Iterators.product(considers, considers)) do (n1, n2)
		row_ind = findfirst(n1 .== name_index)
		col_ind = findfirst(n2 .== name_index)
		df[row_ind, col_ind]
	end
	for n1 in considers, n2 in considers
		if n1 in to_be_removed || n2 in to_be_removed || n1 == n2
			continue
		end
		row_ind = findfirst(n1 .== name_index)
		col_ind = findfirst(n2 .== name_index)
		if abs(df[row_ind, col_ind]) ≥ threshold
			append!(to_be_removed, [df[row_ind, ycol] > df[col_ind, ycol] ? n2 : n1])
		end
	end
	to_be_removed
end

# ╔═╡ 97d8c5d2-58ac-4bb1-a5e5-4eefcfe1edfd
find_multicolinearity(cordf, "SalePrice"; threshold=0.8)

# ╔═╡ Cell order:
# ╠═0ffc59b2-f8f7-11eb-1d41-d7be3a660bff
# ╠═f601a1f4-0da2-457a-8276-97801af40c82
# ╠═4049eb62-6ffa-427b-8a35-7f8b67e51f70
# ╠═24af9da5-8615-4c36-b5df-e10409ca008a
# ╠═b06fbcf9-6f2b-412e-aaea-3497fae925c3
# ╠═2df81d5b-72e2-44b7-b84b-b1cb43bb05b5
# ╠═f7aa44b0-a3c0-470a-a1d6-1274d80ca67e
# ╠═37c0a640-bda7-4e25-916c-ef182de83fc9
# ╠═e8dd05ec-b8ce-4c84-b613-6fa38b4f0fb0
# ╠═0fb1ac77-1d12-4ebf-91e1-983bc925d86d
# ╠═36dc88cc-dbf2-487b-b24a-494c4722ad32
# ╠═a0ba3080-b1ce-4c63-8480-28594c4a69de
# ╠═f025061b-99ac-4663-a104-30bb9def46ba
# ╠═add411c5-4026-4c9c-92a3-e7181ccd6467
# ╠═f7643ebf-da43-42fb-bd75-d204b54d0b08
# ╠═7c52649d-77a0-4fda-991f-89ea0ade4211
# ╠═97d8c5d2-58ac-4bb1-a5e5-4eefcfe1edfd
# ╠═1bcda19e-3bac-48cb-a550-f23a76e72cf2
# ╠═4dbe4a01-bbc3-4274-9ca0-03e0a903d1e1
