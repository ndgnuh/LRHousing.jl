# This module overwrite the default graphic width
# for the sake of comfy-ness
using Gadfly
using Gadfly.Compose
using Cairo
using Fontconfig
using Distributions

const DEF_WIDTH=Compose.default_graphic_width
const DEF_HEIGHT=Compose.default_graphic_height


function qqplot(X; transpose=false, w=DEF_WIDTH, h=DEF_WIDTH)
	set_default_plot_size(w, h)

	d = Normal(0, 1)
	n = length(X)
	sx = sort(X)
	q = map(eachindex(X)) do i
		quantile(d, (i - 0.5) / n)
	end
	theme = Theme(
		discrete_highlight_color=x -> "teal",
		default_color="ivory"
	)
	xlabel = "𝐪"
	ylabel = "𝐫"
	
	if transpose
		sx, q = q, sx
		xlabel, ylabel = ylabel, xlabel
	end
	points = layer(x=q, y=sx, Geom.point, theme, )
	lines = layer(x=q, y=sx, Geom.line, color=[colorant"teal"])
	plot(lines, points, Guide.xlabel(xlabel), Guide.ylabel(ylabel))
end


function coefplot(model; w=DEF_WIDTH, bar_height = 0.5cm, intercept=false, sortabs=false, filter=true, limit=nothing, alpha=0.05)
	abs_col = :AbsCoef
	coef_col = "Coef."
	df = DataFrame(coeftable(model))
	n = size(modelmatrix(model), 1)
	t = cquantile(TDist(n-2), alpha/2)
	codf = @chain begin
		df
		# Remove 95% 
		if filter
			Base.filter(r ->  !(-t ≤ r.t ≤ t), _)
			Base.filter(r -> r["Coef."] ≉ 0, _)
		else
			_
		end
		# Remove intercept term
		if intercept
			_
		else
			Base.filter(r->r["Name"] != "(Intercept)", _)
		end
		# abs value of coef column
		transform(_, coef_col => ByRow(abs) => abs_col)
		# take from top
		if isnothing(limit)
			_
		else
			df = sort(_, coef_col, rev=true)
			k = limit÷2
			[first(df, k); last(df, k)]
		end
		if sortabs
			sort(_, abs_col, rev=false)
		else
			sort(_, coef_col, rev=false)
		end
	end
	set_default_plot_size(w, bar_height * size(codf, 1))
	theme = Theme(bar_highlight=colorant"teal", default_color="teal")
	geo = Geom.bar(orientation=:horizontal)
	p = plot(codf, x="Coef.", y="Name", Guide.xlabel("Value"), Guide.ylabel("Coef"), geo, theme)
end


function plot_pred_eps(pred, e; transpose=false, w=DEF_WIDTH, h=DEF_WIDTH)
	set_default_plot_size(w, h)

	theme = Theme(
		discrete_highlight_color=x -> "teal",
		default_color="ivory"
	)
	xlabel = "𝐲"
	ylabel = "𝛜"
	x, y = pred, e
	
	if transpose
		x, y = y, x
		xlabel, ylabel = ylabel, xlabel
	end
	points = layer(x=x, y=y, Geom.point, theme)
	plot(points, Guide.xlabel(xlabel), Guide.ylabel(ylabel))
end


function plot_eps_hist(e; w=DEF_WIDTH, h=DEF_HEIGHT)

	set_default_plot_size(w, h)

	theme = Theme(
		discrete_highlight_color=x -> "teal",
		default_color="teal"
	)
	plot(x=e, y=e, Guide.xlabel("𝐫"), Guide.ylabel(""), Geom.histogram, theme)
end
