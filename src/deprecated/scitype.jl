using DataFrames


"""
	detect_ignore(df, missing_threshold=0.5, detect_id=true)

Return list of column names, where the column has too many missing, or the name is "Id" and the like.
Set `missing_thresold` to change the rate of missing allowed.
"""
function detect_ignore(df; missing_threshold=0.5, detect_id=true)
	filter(df |> names) do name
		if lowercase(name) == "id" && detect_id
			true
		else
			col = df[!, name]
			n = length(col)
			nm = count(ismissing, n)
			(n / nm) ≥ 0.5
		end
	end
end


"""
	detect(df, T::Type; exclude=String[], use_eltype=true, inv=false)

Return list of column names, where the `eltype(df[!, name]) <: T`.
Use `inv=true` for the inverse.
Use `use_eltype=false` for the whole column type instead of eltype.
Use `exclude` to exclude specific names.
"""
function detect(df, T::Type; exclude=String[], use_eltype=true, inv=false)
	return filter(names(df)) do name
		col = df[!, name]
		if name in exclude
			return false
		else
			S = use_eltype ? eltype(col) : typeof(col)
			cmp = S <: T
			return inv ? !cmp : cmp
		end
	end
end


function detect_categorical(df; exclude=String[])
	n1 = detect(df, Union{Number, Missing}; exclude=exclude, inv=true)
	n2 = detect(df, CategoricalArray; exclude=exclude, use_eltype=false)
	n1 ∪ n2
end


function detect_numeric(df; exclude=String[])
	detect(df, Union{Number, Missing}; exclude=exclude)
end


struct DummyCoding
	columns
	new_columns
	transformation
end


"""
	DummyCoding(df, categoricals)

Return a DummyCoding transformation, which transform categorical columns to dummy coding fake columns and remove the original one.
"""
function DummyCoding(df::AbstractDataFrame, categoricals)
	transforms = mapreduce(vcat, categoricals) do name
		col = df[!, name]
		vals = unique(col)
		@. name => ByRow(isequal(vals)) .=> Symbol(name * "_", vals)
	end
	new_columns = last.(last.(transforms))
	DummyCoding(categoricals, new_columns, transforms)
end


function transform_(df, t::DummyCoding)
	df = transform(df, t.transformation)
	select(df, Not(t.columns))
end


function HierarchicalCoding(H::Dict)
	function maybe_lowercase(x)
		ismissing(x) ? missing : lowercase(x)
	end
	map(collect(H)) do (k, v)
		lv = maybe_lowercase.(v)
		function f(x)
			y = @chain begin
				maybe_lowercase.(x)
				indexin(_, lv)
			end
			@assert !(nothing in y) "Missing level code for $k: $(unique(x))"
			convert(Vector{Int}, y)
		end
		k => f => k
	end
end
