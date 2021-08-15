abstract type Transformation end


struct FillMissing <: Transformation
	column
	stat
	function FillMissing(column, f = mean)
		new(column, f)
	end
end


struct Log1p <: Transformation
	column
end


struct ZNormal <: Transformation
	column
end


struct Categorize <: Transformation
	column
	items
end


struct HierarchyCoding <: Transformation
	column
	items
end


function derive(df, f::HierarchyCoding)
	function g(x)
		y = indexin(x, f.items)
		y = replace(y, nothing => 0)
	end
	transform(df, f.column => g => f.column)
end


function derive(df, f::FillMissing)
	function g(x)
		stat_x = f.stat(collect(skipmissing(x)))
		replace(x, missing => stat_x)
	end
	transform(df, f.column => g => f.column)
end


function derive(df, f::Categorize)
	new_columns = target_columns(f)
	t = map(zip(f.items, new_columns)) do (item, name)
		f.column => ByRow(isequal(item)) => name
	end
	df = select(transform(df, t...), Not(f.column))
end


function derive(df, f::Log1p)
	transform(df, f.column => ByRow(log1p) => f.column)
end


function derive(df, fs::Vector{Transformation})
	for f in fs
		# Do not filter first, because 
		# categorical create new columns
		if f.column in names(df)
			df = derive(df, f)
		end
	end
	return df
end


function safe_znormal(x)
	mx = mean(x)
	sx = std(x; mean=mx)
	y = (x .- mx)
	if isnan(sx) || isapprox(sx, 0)
		norm = sum(@. y^2)
		if isapprox(norm, 0)
			y
		else
			y / norm
		end
	else
		y / sx
	end
end


function derive(df, f::ZNormal)
	transform(df, f.column => safe_znormal => f.column)
end


inv_function(f::Transformation) = nothing
inv_function(f::Log1p) = ByRow(expm1)


function inv_derive(df, f::Transformation)
	g = inv_function(f)
	if isnothing(g)
		df
	else
		transform(df, f.column => g => f.column)
	end
end


function inv_derive(df, fs::Vector{Transformation})
	fs = let names = names(df)
		filter(x -> x.column in names, fs)
	end
	for f in fs
		df = inv_derive(df, f)
	end
	return df
end


function pp(df, preset)
	t1 = mapreduce(vcat, preset.numeric_wo_target; init=Transformation[]) do name
		col = df[!, name]
		fm = FillMissing(name)
		if skewness(col |> skipmissing |> collect) ≥ 0.7
			[FillMissing(name), Log1p(name), ZNormal(name)]
		else
			[FillMissing(name), ZNormal(name)]
		end
	end

	t2 = mapreduce(vcat, preset.hierarchical |> collect; init=Transformation[]) do (n, v)
		[HierarchyCoding(n, v), ZNormal(n)]
	end

	t3 = mapreduce(vcat, preset.categorical; init=Transformation[]) do n
		vals = unique(df[!, n])
		f = Categorize(n, vals)
		new_columns = target_columns(f)
		zs = map(ZNormal, new_columns)
		[f; zs]
	end

	t4 = let t =  Log1p[]
		col = df[!, preset.target]
		while skewness(col) ≥ 0.7 && length(t) ≤ 2
			push!(t, Log1p(preset.target))
			col = log1p.(col)
		end
		t
	end

	t1 ∪ t2 ∪ t3 ∪ t4
end


target_columns(f::Transformation) = [f.column]
target_columns(f::Categorize) = [f.column * "_" * string(item) for item in f.items]
target_columns(fs::Vector{Transformation}) = unique(reduce(vcat, target_columns.(fs)))
