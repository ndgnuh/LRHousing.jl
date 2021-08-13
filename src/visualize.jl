# This module overwrite the default graphic width
# for the sake of comfy-ness
using Gadfly
using Gadfly.Compose

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
	ylabel = "𝐱"
	
	if transpose
		sx, q = q, sx
		xlabel, ylabel = ylabel, xlabel
	end
	points = layer(x=q, y=sx, Geom.point, theme, )
	lines = layer(x=q, y=sx, Geom.line, color=[colorant"teal"])
	plot(lines, points, Guide.xlabel(xlabel), Guide.ylabel(ylabel))
end


function coefplot(df; bar_height = 0.75cm, intercept=false)
	codf = @chain begin
		df
		filter(r ->  !(r["Lower 95%"] ≤ 0 ≤ r["Upper 95%"]), _)
		if intercept
			_
		else
			filter(r->r["Name"] != "(Intercept)", _)
		end
		transform(_, "Coef." => ByRow(abs) => "AbsCoef")
		sort(_, "AbsCoef", rev=false)
	end
	set_default_plot_size(DEF_WIDTH, bar_height * size(codf, 1))
	theme = Theme(bar_highlight=colorant"teal", default_color="teal")
	geo = Geom.bar(orientation=:horizontal)
	p = plot(codf, x="Coef.", y="Name", geo, theme)
end
