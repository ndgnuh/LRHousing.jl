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


function rmse(pred, y; normalize=true)
	n = length(y)
	r = sqrt(mean(@. (pred - y)^2) / n)
	if normalize
		#= maxy = max(pred..., y...) =#
		#= miny = min(pred..., y...) =#
		#= r / (maxy - miny) =#
		r / iqr(y)
	else
		r
	end
end


function kfold_rmse(data, preset, k = 10; normalize=true)
	n = size(data, 1)
	idx = collect(Iterators.partition(1:n, n÷k))
	tf = pp(data, preset)
	columns = target_columns(tf)
	f = formula(columns, preset.target)    

	R = map(enumerate(idx)) do (k, idx)
		train = derive(data[Not(idx), :], tf)
		test = derive(data[idx, :], tf)
		model = lm(f, train)
		pred = predict(model, test)
		rmse(pred, test[!, preset.target]; normalize=normalize)
	end
	mean(R)
end


function rsquared(model, y)
	my = mean(y)
	stot = sum(@. (y - my)^2)
	sres = sum(residuals(model).^2)
	1 - sres/stot
end


export lm

end # module
