"""
	BoxCox{T}(λ1, λ2=0)

This struct is used to store the lambda values for boxcox transform, since the value is only search-able on train data.
"""
struct BoxCox
	λ1
	λ2
	BoxCox(λ1, λ2=0) = new(λ1, λ2)
end


function BoxCox(X::AbstractArray)
	λ1, λ2 = boxcox_gridsearch(X)
	BoxCox(λ1, λ2)
end


function (f::BoxCox)(X; inv=false)
	if inv
		inv_boxcox(X, f.λ1, f.λ2)
	else
		boxcox(X, f.λ1, f.λ2)
	end
end



"""
	boxcox(x, λ₁, λ₂ = 0)

Return the boxcox transformed `x`.
"""
function boxcox(x, λ1, λ2 = 0)
	if λ1 == 0
		log(x + λ2)
	else
		((x + λ2)^λ1 - 1) / λ1
	end
end


function inv_boxcox(x, λ1, λ2 = 0)
	y = if λ1 == 0
		exp(x)
	else
		(x * λ1 + 1)^(1/λ1)
	end
	y - λ2
end


"""
	auto_boxcox(X, λ₂ = 0; r = -5:0.01:5)

Return tuple `(λ₁, λ₂, Y, pv)` where:
- `λ₁`, `λ₂` are boxcox λ-s value
- `Y` are boxcox transformed values of `X`
- `pv` is `pvalue` of the `OneSampleADTest`

Lambda values are automatically calculated using grid search by finding the max of the `pvalue` of `OneSampleADTest`. One can pass a range to `λ₂` to grid search for `λ₂`, too.
"""
function auto_boxcox(X, λ2 = 0; r = -5:0.01:5, inv=false)
	λ1, λ2 = boxcox_gridsearch(X, r, λ2)
	if inv
		boxcox.(X, λ1, λ2)
	else
		inv_boxcox.(X, λ1, λ2)
	end
end


"""
	boxcox_gridsearch(X, l1 = range(start=-5, stop=5, step=0.01), l2 = 0)

Return (λ1, λ2) of BoxCox transformation, grid search evaluated by finding max of `pvalue(OneSampleADTest(...))`.
"""
function boxcox_gridsearch(X, l1 = range(start=-5, stop=5, step=0.01), l2 = 0)
	iter = Iterators.product(l1, l2)
	dist = Normal(0, 1)
	grid = map(iter) do (l1, l2)
		@chain begin
			boxcox.(X, l1, l2)
			standardize(ZScoreTransform, _)
			OneSampleADTest(_, dist)
			pvalue(_)
			(l1 = l1, l2 = l2, pv = _)
		end
	end
	@chain begin
		grid
		filter(x -> !isnan(x.pv), _)
		sort(_, by = x -> x.pv, rev=true)
		first(_)
	end
end


function create_boxcox_transform(df, numeric; exclude=String[], use_log1p=false)
	t = map(numeric) do name
		col = Vector(df[!, name])
		if skewness(col) ≥ 0.75
			f = if use_log1p
				(x; inv=false) -> inv ? exp1m(x) : log1p(x)
			else
				l1, l2 = boxcox_gridsearch(col)
				BoxCox(l1, l2)
			end
			name => ByRow(f) => name
		else
			nothing
		end
	end
	filter(!isnothing, t)
end
