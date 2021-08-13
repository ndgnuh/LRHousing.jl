module LRHousing

using Chain: @chain
using StatsBase
using StatsBase.Statistics
using DataFrames
using CSV
using GLM
include("preset.jl")
include("visualize.jl")
include("anomalies.jl")
include("transformation.jl")


function read_data(path; missingstrings=["NA"], normalizenames=true)
	CSV.read(path, DataFrame, missingstrings=missingstrings, normalizenames=normalizenames)
end


"""
	fill_missing(X, stat)

Fill missing inside array with statistic.

## Example
```julia
using Statistics
fill_missing([1,2,3], mean)
```
"""
function fill_missing(X, stat)
	@chain begin
		X
		replace(_, missing => stat(filter(!ismissing, _)))
		convert.(nonmissingtype(eltype(_)), _)
	end
end


function fill_missing(df::AbstractDataFrame, numeric=detect_numeric(df))
	df = copy(df)
	for name in numeric
		df[!, name] = fill_missing(df[!, name], mean)
	end
	return df
end


function formula(columns, target)
	lhs = Term(Symbol(target))
	columns = filter(!isequal(target |> String), String.(columns))
	rhs = @. Term(Symbol(columns))
	f = FormulaTerm(lhs, (ConstantTerm(1), rhs...))
end


function fit(data, columns, target)
	formula(columns, target)
	lm(f, data)
end


export DataPipeline, create_formula, lm, create_linear_model

end # module
