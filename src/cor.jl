using LinearAlgebra
using StatsBase


@noinline function compute_cordf(df, columns)
	result = DataFrame(col=columns)
	function compute_cor(name_1, name_2)
		col_1 = df[!, name_1]
		col_2 = df[!, name_2]
		StatsBase.cor(col_1, col_2)
	end
	transformations = map(columns) do name_1
		:col => ByRow(name_2 -> compute_cor(name_1, name_2)) => Symbol(name_1)
	end
	transform(result, transformations...)
end


function find_multicolinearity(cordf, ycol, threshold::Number)
	to_be_removed = String[]
	sizehint!(to_be_removed, size(cordf, 1))
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


function find_multicolinearity(df, columns, ycol; threshold_step=0.01, threshold_max=1.0, threshold_min=0.5)
	t_range = reverse(collect(range(start=threshold_min, stop=threshold_max, step=threshold_step)))
	df = select(df, columns)
	cordf = compute_cordf(df, columns)
	for t in t_range
		removed = find_multicolinearity(cordf, ycol, t)
		df2 = select(df, Not(removed))
		if rank(Matrix(df2)) == length(names(df2))
			return removed, t
		end
	end
	String[], threshold_min
end
