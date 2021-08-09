### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 38144072-3fab-478c-aa25-947c7086d7d9
begin
	using Pkg
	using Revise
	Pkg.activate("..")
	using LRHousing
end

# ╔═╡ c060061b-1b8d-45f6-98c0-c4d9e28c16f7
begin	
	struct DataLine
		idx_numeric
		log_numeric
		categorical
		ignore
		function DataLine(df, ignore)
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
				filter(name -> eltype(df[!, name]) <: Number, _)
			end
			log_numeric = filter(name -> skewness(df[!, name]) ≥ 0.75, numeric)
			categorical = filter(!in(numeric), allnames)
			new(numeric, log_numeric, categorical, ignore)
		end
	end
	
	
	function (l::DataLine)(df)
		df = select(df, Not(l.ignore))
		function znorm(X)
			X = replace(X, missing => mean(filter(!ismissing, X)))
			standardize(ZScoreTransform, convert.(Float32, X))
		end
		function categorical_(X)
			X = replace(X, missing => mode(filter(!ismissing, X)))
			categorical(X)
		end
		df = @chain begin
			l.idx_numeric
			map(name -> (name => znorm => name), _)
			transform(df, _...)
		end
		df = @chain begin
			l.categorical
			map(name -> (name => categorical_ => name), _)
			transform(df, _...)
		end
		return df
	end
end

# ╔═╡ 34a4eb8d-b724-4f28-9d5c-159a3c2b1a6d
function read_csv(file)
	df = @chain begin
		CSV.read(file, DataFrame, missingstrings=["NA"], normalizenames=true)
# 		map(names(_)) do name
# 			col = _[!, name]
# 			col = if eltype(col) <: AbstractString
# 				categorical(col)
# 			else
# 				col
# 			end
# 			name => col
# 		end
# 		DataFrame(_)
# 	end
	end	
end

# ╔═╡ 91eaf5c4-909f-4d62-877c-2f807a872fc0
train_data = read_csv("../data/train.csv")

# ╔═╡ ea0bab7a-6260-4995-a775-857f66651da3
preprocess = DataLine(train_data, ["Id"])

# ╔═╡ 51afcb1f-f749-496c-acc5-4cecb4e4d1df
preprocess(train_data)

# ╔═╡ 70d6defb-8557-43e1-8a9a-639640d2dd67
preprocess(train_data)

# ╔═╡ 5b242981-a0ef-4638-a3b3-d35617686744
test_data = read_csv("../data/test.csv")

# ╔═╡ 15c9cc08-3834-4922-9789-52023a9a2489
function single_functional_term(f, x)
	symbol = Expr(:call, Symbol(f), x)
	fanon = eval(:(($x,) -> log($x)))
	StatsModels.capture_call(f, fanon, (x,), symbol, [Term(x)])
end

# ╔═╡ 5b3a0677-9c64-4669-b90e-8ad7286b0531
e = :(f(x))

# ╔═╡ 5718f7ce-328a-4705-85ad-052494be8e93
predictor_names = setdiff(names(train_data), ["Id", "SalePrice"])

# ╔═╡ 25981a26-7762-4daa-8b69-936a027a88dc
numeric_columns = @chain begin
	predictor_names
	filter(x -> eltype(train_data[!, x]) <: Number, _)
end

# ╔═╡ 8fe249bd-5102-4808-baf7-e769e4b1056a
FormulaTerm(Term(:y), (Term(:x),))

# ╔═╡ 0a9b7ae3-bd8f-4b12-95a9-c132715d7f1b
f = let res = Term(:SalePrice)
	pres = map(numeric_columns) do name
		name = Symbol(name)
		if skewness(train_data[!, name]) > 0.75
			single_functional_term(log, name)
		else
			Term(name)
		end
	end
	FormulaTerm(res, (pres...,))
end

# ╔═╡ 65ed182a-fea7-472d-86c9-e51958ebf6d2
lm(f, train_data)

# ╔═╡ febc052d-82f2-455e-b35b-3fc230899657
ex = Expr(:call, :~, :y, Expr(:call, :+, 1, :x1, :x2))

# ╔═╡ d96899e6-3484-4b0e-b902-b1c709d9c6f1
dump(ex)

# ╔═╡ 4ceaa564-ee7a-47c6-ae2f-efe0f94f968b
ex2 = :(y ~ 1 + x + x2)

# ╔═╡ 424a6f2d-4aa0-46fb-b2a6-527cbedef366
function build_formular(y, xs)
	e = Expr(:call, :~, Symbol(y), Expr(:call, :+, 1, Symbol.(xs)...))
	eval(:(@formula $e))
end

# ╔═╡ 37d737c9-6be9-40f0-8434-53eae3d5936b
f2 = build_formular(:SalePrice, numeric_columns)

# ╔═╡ f3e33cfe-4a73-4033-942e-2dc0b85fb6d7
lm(f2, train_data)

# ╔═╡ ab1753c5-8672-45e2-ac68-f5bf1d6374fc
eval(:(@formula $ex))

# ╔═╡ d3e5677e-a491-4c58-9f7a-2299339fc299
InteractionTerm((Term(:x), Term(:y))

# ╔═╡ e8f21844-31b1-45a0-a4cd-a36c32a9292e
let i = :a
	StatsModels.capture_call(log, (a,)->log(a), (:a,), :(log(a)), [Term(:a)])
	# [StatsModels.Term($i)]
	# )
	# ~ Term(:AX))
	# end
end

# ╔═╡ Cell order:
# ╠═38144072-3fab-478c-aa25-947c7086d7d9
# ╠═c060061b-1b8d-45f6-98c0-c4d9e28c16f7
# ╠═ea0bab7a-6260-4995-a775-857f66651da3
# ╠═51afcb1f-f749-496c-acc5-4cecb4e4d1df
# ╠═70d6defb-8557-43e1-8a9a-639640d2dd67
# ╠═34a4eb8d-b724-4f28-9d5c-159a3c2b1a6d
# ╠═91eaf5c4-909f-4d62-877c-2f807a872fc0
# ╠═5b242981-a0ef-4638-a3b3-d35617686744
# ╠═15c9cc08-3834-4922-9789-52023a9a2489
# ╠═5b3a0677-9c64-4669-b90e-8ad7286b0531
# ╠═5718f7ce-328a-4705-85ad-052494be8e93
# ╠═25981a26-7762-4daa-8b69-936a027a88dc
# ╠═8fe249bd-5102-4808-baf7-e769e4b1056a
# ╠═0a9b7ae3-bd8f-4b12-95a9-c132715d7f1b
# ╠═65ed182a-fea7-472d-86c9-e51958ebf6d2
# ╠═febc052d-82f2-455e-b35b-3fc230899657
# ╠═d96899e6-3484-4b0e-b902-b1c709d9c6f1
# ╠═4ceaa564-ee7a-47c6-ae2f-efe0f94f968b
# ╠═424a6f2d-4aa0-46fb-b2a6-527cbedef366
# ╠═37d737c9-6be9-40f0-8434-53eae3d5936b
# ╠═f3e33cfe-4a73-4033-942e-2dc0b85fb6d7
# ╠═ab1753c5-8672-45e2-ac68-f5bf1d6374fc
# ╠═d3e5677e-a491-4c58-9f7a-2299339fc299
# ╠═e8f21844-31b1-45a0-a4cd-a36c32a9292e
