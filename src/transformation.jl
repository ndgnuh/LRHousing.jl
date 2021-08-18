abstract type Transformation end


struct FillMissing <: Transformation
	column
	stat
	function FillMissing(column, f = mean)
		new(column, f)
	end
end


struct MinMaxNormalize <: Transformation
	column
	min
	r
	MinMaxNormalize(column, X) = new(column, minimum(X), maximum(X) - minimum(X))
end


struct Log1p <: Transformation
	column
end


struct ZNormal <: Transformation
	column
end


struct ZNormalize <: Transformation
	column
	μ
	σ
	function ZNormalize(column, X)
		sx = std(X)
		ex = mean(X)
		new(column, ex, sx)
	end
end


struct Categorize <: Transformation
	column
	items
	leftout
	function Categorize(column, X)
		items = unique(X)
		cm = countmap(items)
		_, idx = findmin(item -> cm[item], items)
		leftout = items[idx]
		items = setdiff(items, [leftout])
		new(column, items, leftout)
	end
end


struct HierarchyCoding <: Transformation
	column
	items
end


function derive(df, f::MinMaxNormalize)
	transform(df, f.column => ByRow(x -> (x - f.min) / f.r) => f.column)
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


function derive(df, f::ZNormalize)
	transform(df, f.column => ByRow(x -> (x - f.μ) / f.σ) => f.column)
end


function derive(df, f::ZNormal)
	transform(df, f.column => safe_znormal => f.column)
end


inv_function(f::Transformation) = nothing
inv_function(f::ZNormalize) = ByRow(x -> x * f.σ + f.μ)
inv_function(f::MinMaxNormalize) = ByRow(x -> x * f.r + f.min)
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
	for f in reverse(fs)
		if f.column in names(df)
			df = inv_derive(df, f)
		end
	end
	return df
end


function pp(df, preset; normalizer=MinMaxNormalize, log_x=true, normalize_target=true)
	t1 = mapreduce(vcat, preset.numeric; init=Transformation[]) do name
		col = df[!, name]
		fm = FillMissing(name)
		if log_x && skewness(col |> skipmissing |> collect) ≥ 0.7
			[FillMissing(name), Log1p(name)]
		else
			[FillMissing(name)]
		end
	end

	t2 = map(preset.hierarchical |> collect) do (n, v)
		HierarchyCoding(n, v)
	end

	t3 = map(preset.categorical) do n
		Categorize(n, df[!, n])
	end

	t = t1 ∪ t2 ∪ t3

	if isnothing(normalizer)
		t
	else
		df2 = derive(df, t)
		t4 = mapreduce(vcat, target_columns(t); init=normalizer[]) do n
			if n == preset.target && !normalize_target
				return normalizer[]
			end
			col = df2[!, n]
			[normalizer(n, col)]
		end
		t ∪ t4
	end
end


target_columns(f::Transformation) = [f.column]
target_columns(f::Categorize) = [f.column * "_" * string(item) for item in f.items]
target_columns(fs::Vector{Transformation}) = unique(reduce(vcat, target_columns.(fs)))

ignored_columns(f::Transformation) = String[]
ignored_columns(f::Categorize) = ["$(f.column)_$(f.leftout)"]
ignored_columns(fs::Vector{Transformation}) = unique(mapreduce(ignored_columns, vcat, fs))
