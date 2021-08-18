using CategoricalArrays


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
crammerv(x::CategoricalArray, y) = crammerv(x, bin_number_vector(y, 10))
crammerv(x, y::CategoricalArray) = crammerv(bin_number_vector(x, 10), y)


function bin_number_vector(X, k=10)
	minx = minimum(X)
	maxx = maximum(X)
	bins = range(start=minx, stop=maxx, length=k)
	map(x -> findfirst(x .< bins), X)
end


function compute_cordf(df)
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


function find_multicolinearity(cordf, ycol; threshold=0.7)
	to_be_removed = String[]
	sizehint!(to_be_removed, size(cordf, 1)÷3)
	considers = setdiff(cordf.col, ["SalePrice"])
	name_index = String.(cordf.col)
	df = select(cordf, Not("col"))
	for n1 in considers, n2 in considers
		if n1 in to_be_removed || n2 in to_be_removed || n1 == n2
			continue
		end
		row_ind = findfirst(n1 .== name_index)
		col_ind = findfirst(n2 .== name_index)
		if abs(df[row_ind, col_ind]) > threshold
			append!(to_be_removed, [abs(df[row_ind, ycol]) > abs(df[col_ind, ycol]) ? n2 : n1])
		end
	end
	to_be_removed
end
