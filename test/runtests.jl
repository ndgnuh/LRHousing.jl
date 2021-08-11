using Test
using CSV
using DataFrames
using LRHousing
using GLM

#= basedir = joinpath(@__DIR__, "..") =#

#= train = LRHousing.read_data(joinpath(basedir, "data", "train.csv")) =#
#= pl = DataPipeline(train; ignore = ["Id"]) =#
#= train_p = pl(train) =#
#= fm = create_formula(pl,  :SalePrice) =#
#= model = lm(fm, train_p) =#
#= display(model) =#

#= test = LRHousing.read_data(joinpath(basedir, "data", "test.csv")) =#
#= # TODO, remove this constraint =#
#= test.SalePrice = fill(0, size(test, 1)) =#
#= test_p = pl(test) =#

#= # TODO, automatic exp if the functional term is in the respond =#
#= test.SalePrice = exp.(predict(model, test_p)) =#
#= display(test) =#

@testset "Transformation" begin
	x = rand() .+ 10
	for l1 in -5:0.01:5
		y = LRHousing.boxcox(x, l1)
		x′ = LRHousing.inv_boxcox(y, l1)
		@test x ≈ x′
	end
end
