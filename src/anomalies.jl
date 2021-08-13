using InteractiveUtils


abstract type AnomaliesMethod end


struct IQRMethod <: AnomaliesMethod
	lower
	upper
	IQRMethod(lower = 0.25, upper = 0.75) = new(lower, upper)
end


"""
	StdAroundMean(k = 3)

Return standard-deviation-around-mean method, anomalies are outside of μ ± k⋅σ.
"""
struct StdAroundMean <: AnomaliesMethod
	k
	StdAroundMean(k = 3) = new(k)
end


struct MedianAbsoluteDeviation <: AnomaliesMethod
	k
	dist
	MedianAbsoluteDeviation(k = 3, dist = Normal(0, 1)) = new(k, dist)
end


"""
	find_anomalies(X, lower, upper)

Return all `i` where `X[i] < lower` or `X[i] > upper`.
"""
function find_anomalies(X, lower, upper)
	findall(x -> !(lower ≤ x ≤ upper), X)
end



"""
	find_anomalies(X, m::AnomaliesMethod)

Return all `i` where `X[i]` is anomalies, using method `m`.
Method of detecting anomalies includes:

$(join(map(x -> "- `$(x)`", InteractiveUtils.subtypes(AnomaliesMethod)), "\n"))
"""
function find_anomalies(X, m::AnomaliesMethod)
	lower, upper = lower_upper(X, m)
	find_anomalies(X, lower, upper)
end


"""
	lower_upper(X, method::AnomaliesMethod)

Return the lower and upper bound for "normal data", using an `AnomaliesMethod`.
Method of detecting anomalies includes:

$(join(map(x -> "- `$(x)`", InteractiveUtils.subtypes(AnomaliesMethod)), "\n"))
"""
function lower_upper(X, method::IQRMethod)
	lower = quantile(X, method.lower)
	upper = quantile(X, method.upper)
	lower, upper
end


function lower_upper(X, method::StdAroundMean)
	mx = mean(X)
	sx = std(X)
	lower = mx - method.k * sx
	upper = mx + method.k * sx
	lower, upper
end


function lower_upper(X, method::MedianAbsoluteDeviation)
	m = median(X)
	mad = quantile(method.dist, 0.75) * median(abs.(X .- m))
	lower = m - method.k * mad
	upper = m + method.k * mad
	lower, upper
end
