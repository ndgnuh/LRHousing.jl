module LRHousing

using Chain: @chain
using StatsBase
using CategoricalArrays
using DataFrames
using CSV
using GLM
using Setfield # lens


"""
	DataPipeline(df, ignore)

Returns a preprocess rule for a certain structre of dataframe. `DataPipeline` fields
- `numeric`: All numeric column names
- `log_numeric`: All numeric column names that must be log transform first
- `categorical`: All names of categorical columns
- `ignore`: name of ignored columns, specified columns and columns with more than 50% missing are skipped
- `target`: name of the target columns

## Example
```julia-repl
preprocess = DataPipeline(train_data, ["id"]);
preprocess(test_data)
```
"""
struct DataPipeline
	numeric::Vector{Symbol}
	log_numeric::Vector{Symbol}
	categorical::Vector{Symbol}
	ignore::Vector{Symbol}
	target::Vector{Symbol}
	function DataPipeline(df; ignore=String[], target=Symbol[])
		ignore = @chain begin
			names(df)
			filter(name -> (count(ismissing, df[!, name]) / length(df[!, name])) ≥ 0.5, _)
			vcat(_, ignore)
			Symbol.(_)
		end
		allnames = @chain begin
			names(df)
			Symbol.(_)
			filter(!in(ignore), _)
			filter(!isequal(ignore), _)
		end
		numeric = @chain begin
			allnames
			filter(name -> Bool != eltype(df[!, name]), _)
			filter(name -> eltype(skipmissing(df[!, name])) <: Number, _)
		end
		log_numeric = filter(numeric) do name
			@chain begin
				df[!, name]
				skipmissing(_)
				collect(_)
				skewness(_)
				_ ≥ 0.75
			end
		end
		categorical = filter(!in(numeric), allnames)
		new(numeric, log_numeric, categorical, ignore, target)
	end
	function DataPipeline(; kwargs...)
		new(kwargs[:numeric],
		    kwargs[:log_numeric],
		    kwargs[:categorical],
		    kwargs[:ignore],
		    kwargs[:target],
		)
	end
	# This method is for Setfield package
	DataPipeline(args...) = new(args...)
end


# Generate add_* and remove_* methods
# These method create a new instance, not modifying the current type
for field in fieldnames(LRHousing.DataPipeline)
    add_name = Symbol("add_$field")
    remove_name = Symbol("remove_$field")
    expr = quote

        @doc $"""
	add_$field(pl, names_)
        
Return a new datapipeline with added `names_` in the `$field` field.
## Parameters:
- `pl`: A `DataPipeline`
- `names_`: `Symbol` or `Vector{Symbol}`
        """
        function $add_name(pl, s::AbstractArray)
            @set pl.$(field) = append!(copy(pl.$(field)), Symbol.(s))
        end
        function $add_name(pl, s)
            @set pl.$(field) = append!(copy(pl.$(field)), [Symbol(s)])
        end

        @doc $"""
	remove_$field(pl, names_)
        
Return a new datapipeline with removed `names_` in the `$field` field.

## Parameters:
- `pl`: A `DataPipeline`
- `names_`: `Symbol` or `Vector{Symbol}`
        """
        function $remove_name(pl, s::AbstractArray)
            @set pl.$(field) = setdiff(pl.$(field), Symbol.(s))
        end
        function $remove_name(pl, s)
            @set pl.$(field) = setdiff(pl.$(field), [Symbol.(s)])
        end
	export $add_name, $remove_name
    end
    eval(expr)
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


"""
	fill_missing(stat)

Returns the function that fill missings with `stat`
"""
function fill_missing(stat)
	return x -> fill_missing(x, stat)
end

	
"""
	(::DataPipeline)(df)

Return a new dataframe contains preprocessed data.
- missing value are replaced by mean/mode, if the data is numeric/categorical
- numeric value are z-transformed
- ignored columns is left out
"""
function (pl::DataPipeline)(df; standard=true, log_inplace=false)
	# fill missing
	df = @chain begin
		pl.numeric
		map(name -> (name => fill_missing(mean) => name), _)
		transform(df, _...)
	end
	df = @chain begin
		pl.categorical
		map(name -> (name => fill_missing(mode) => name), _)
		transform(df, _...)
	end

	if standard
		znorm(x) = standardize(ZScoreTransform, x)
		df = @chain begin
			pl.numeric
			setdiff(_, pl.log_numeric)
			setdiff(_, pl.target)
			map(name -> (name => znorm => name), _)
			transform(df, _...)
		end
	end

	if log_inplace
		df = @chain begin
			pl.log_numeric
			map(name -> (name => ByRow(log1p) => "$name"), _)
			transform(df, _...)
		end
	end

	df = @chain begin
		pl.categorical
		map(name -> (name => categorical => name), _)
		transform(df, _...)
	end
	return df
end


"""
	functional_term(f, arg...)

Return a functional term of StatModels.

## Example
```julia
functional_term(log, :x) # (x) -> log(x)
functional_term(log, :(x * y)) # (x, y) -> log(x * y)
functional_term(*, :x, :y)
```
"""
function functional_term(f, arg_expr...)
	expr = Expr(:call, Symbol(f), arg_expr...)
	eval(:(@formula somethingsomethingvarhopefullynodup ~ $expr)).rhs
end


"""
	single_functional_term(f, x)

Same as `functional_term`, but doesn't use macro and only works with one arg.
"""
function single_functional_term(f, x)
	symbol = Expr(:call, Symbol(f), x)
	fanon = eval(:(($x,) -> log($x)))
	GLM.StatsModels.capture_call(f, fanon, (x,), symbol, [Term(x)])
end


"""
	create_formula(pl::DataPipeline, yname; log_term=true, categorical_term=true)

Return a StatModels formula. Log numeric columns will be transformed to
functional terms with `log`.
"""
function create_formula(pl::DataPipeline, yname; log_term=true, categorical_term=true)
	is_not_target = x -> Symbol(x) != Symbol(yname)
	lhs = if yname in pl.log_numeric
		functional_term(log1p, Symbol(yname))
	else
		Term(Symbol(yname))
	end
	rhs = @chain begin
		pl.numeric
		log_term ? setdiff(_, pl.log_numeric) : _
		categorical_term ? _ ∪ pl.categorical : _
		filter(is_not_target, _)
		map(Term, _)
	end
	rhs = if log_term
		@chain begin
			pl.log_numeric
			filter(is_not_target, _)
			map(name -> functional_term(log1p, name), _)
			vcat(rhs, _)
		end
	else
		rhs
	end
	FormulaTerm(lhs, (ConstantTerm(1), rhs...,))
end


"""
	create_linear_model(pl::DataPipeline, yname, data; kwargs...)

Return a GLM fitted model using `create_formula`. `kwargs` are `create_formula` kwargs.
"""
function create_linear_model(pl::DataPipeline, yname, data; kwargs...)
	fm = create_formula(pl, yname; kwargs...)
	lm(fm, data)
end


function read_data(path, missingstrings=["NA"])
	CSV.read(path, DataFrame, missingstrings=missingstrings, normalizenames=true)
end

export DataPipeline, create_formula, lm, create_linear_model

end # module
