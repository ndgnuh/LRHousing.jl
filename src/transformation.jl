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
function auto_boxcox(X, λ2 = 0; r = -5:0.01:5)
	iter = Iterators.product(r, λ2)
	dist = Normal(0, 1)

	grid = map(iter) do (l1, l2)
		Y = boxcox.(X, l1, l2)
		@chain begin
			Y
			standardize(ZScoreTransform, _)
			OneSampleADTest(_, dist)
			pvalue(_)
			(l1 = l1, l2 = l2, Y = Y, pv = _)
		end
	end
	@chain begin
		grid
		filter(x -> !isnan(x.pv), _)
		sort(_, by = x -> x.pv, rev=true)
		first(_)
	end
end
