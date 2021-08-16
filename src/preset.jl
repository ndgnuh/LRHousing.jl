@Base.kwdef struct Preset
	hierarchical
	hierarchical_names
	numeric
	categorical
	numeric_wo_target
	target
end

const AMES_MANUAL = let
	numeric = ["SalePrice"
		   "LotFrontage"
		   "LotArea"
		   "OverallQual"
		   "OverallCond"
		   "BsmtFinSF1"
		   "BsmtFinSF2"
		   "BsmtUnfSF"
		   "1stFlrSF"
		   "2ndFlrSF"
		   "LowQualFinSF"
		   "GrLivArea"
		   "BsmtFullBath"
		   "BsmtHalfBath"
		   "FullBath"
		   "HalfBath"
		   "BedroomAbvGr"
		   "KitchenAbvGr"
		   "TotRmsAbvGrd"
		   "Fireplaces"
		   "GarageCars"
		   "GarageArea"
		   "WoodDeckSF"
		   "EnclosedPorch"
		   "OpenPorchSF"
		   "3SsnPorch"
		   "ScreenPorch"
		   "PoolArea"
		   "MiscVal"
		   "MasVnrArea"
		   "TotalBsmtSF"
		   "YearBuilt"
		   "YearRemodAdd"
		   "GarageYrBlt"
		   "MoSold"
		   "YrSold"
		   ]

	categorical = ["MSSubClass"
		       "MSZoning"
		       "RoofStyle"
		       "RoofMatl"
		       "Exterior1st"
		       "Exterior2nd"
		       "MasVnrType"
		       "Foundation"
		       "Street"
		       "Alley"
		       "LandContour"
		       "LotConfig"
		       "Neighborhood"
		       "Condition1"
		       "Condition2"
		       "BldgType"
		       "HouseStyle"
		       "Heating"
		       "GarageType"
		       ]

	hierarchical = ["PoolQC" => [missing, "Fa", "TA", "Gd", "Ex"]
			"Fence" => [missing, "MnWw", "GdWo", "MnPrv", "GdPrv"]
			"PavedDrive" => [missing, "N", "P", "Y"]
			"GarageCond" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"Utilities" => [missing, "ELO", "NoSeWa", "NoSewr", "AllPub"]
			"ExterQual" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"KitchenQual" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"ExterCond" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"BsmtQual"=>[missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"BsmtCond"=>[missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"BsmtExposure" => [missing, "No", "Mn", "Av", "Gd"]
			"BsmtFinType1" => [missing, "Unf", "LwQ", "Rec", "BLQ", "ALQ", "GLQ"]
			"BsmtFinType2" => [missing, "Unf", "LwQ", "Rec", "BLQ", "ALQ", "GLQ"]
			"CentralAir" => [missing, "N", "Y"]
			"GarageQual" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"GarageCond" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"HeatingQC" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"LotShape" => [missing, "IR1", "IR2", "IR3", "Reg"]
			"FireplaceQu" => [missing, "Po", "Fa", "TA", "Gd", "Ex"]
			"Functional" => [missing, "Sal", "Sev", "Maj2", "Maj1", "Mod", "Min2", "Min1", "Typ"]
			"GarageFinish" => [missing, "Unf", "RFn", "Fin"]
			"LandSlope" => [missing, "Sev", "Mod", "Gtl"]
			"Electrical" => [missing, "FuseP", "FuseF", "Mix", "FuseA", "SBrkr"]
			]

	hierarchical = Dict(hierarchical...)
	target = "SalePrice"
	numeric_wo_target = setdiff(numeric, [target])
	hierarchical_names=collect(keys(hierarchical))

	Preset(hierarchical=hierarchical,
	       hierarchical_names=hierarchical_names,
	       numeric=numeric,
	       categorical=setdiff(categorical, hierarchical_names),
	       numeric_wo_target=numeric_wo_target,
	       target=target)
end

const AMES_AUTO = let
	target = "SalePrice"
	numeric = ["MSSubClass", "LotFrontage", "LotArea", "OverallQual", "OverallCond", "YearBuilt", "YearRemodAdd", "MasVnrArea", "BsmtFinSF1", "BsmtFinSF2", "BsmtUnfSF", "TotalBsmtSF", "1stFlrSF", "2ndFlrSF", "LowQualFinSF", "GrLivArea", "BsmtFullBath", "BsmtHalfBath", "FullBath", "HalfBath", "BedroomAbvGr", "KitchenAbvGr", "TotRmsAbvGrd", "Fireplaces", "GarageYrBlt", "GarageCars", "GarageArea", "WoodDeckSF", "OpenPorchSF", "EnclosedPorch", "3SsnPorch", "ScreenPorch", "PoolArea", "MiscVal", "MoSold", "YrSold", "SalePrice"]
	categorical = ["MSZoning", "Street", "Alley", "LotShape", "LandContour", "Utilities", "LotConfig", "LandSlope", "Neighborhood", "Condition1", "Condition2", "BldgType", "HouseStyle", "RoofStyle", "RoofMatl", "Exterior1st", "Exterior2nd", "MasVnrType", "ExterQual", "ExterCond", "Foundation", "BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1", "BsmtFinType2", "Heating", "HeatingQC", "CentralAir", "Electrical", "KitchenQual", "Functional", "FireplaceQu", "GarageType", "GarageFinish", "GarageQual", "GarageCond", "PavedDrive", "PoolQC", "Fence", "MiscFeature", "SaleType", "SaleCondition"]
	Preset(hierarchical=Dict(),
	       hierarchical_names=String[],
	       numeric=numeric,
	       categorical=categorical,
	       numeric_wo_target=setdiff(numeric, [target]),
	       target=target)
end

const AMES_NUMERIC = let
	target = "SalePrice"
	numeric = ["MSSubClass", "LotFrontage", "LotArea", "OverallQual", "OverallCond", "YearBuilt", "YearRemodAdd", "MasVnrArea", "BsmtFinSF1", "BsmtFinSF2", "BsmtUnfSF", "TotalBsmtSF", "1stFlrSF", "2ndFlrSF", "LowQualFinSF", "GrLivArea", "BsmtFullBath", "BsmtHalfBath", "FullBath", "HalfBath", "BedroomAbvGr", "KitchenAbvGr", "TotRmsAbvGrd", "Fireplaces", "GarageYrBlt", "GarageCars", "GarageArea", "WoodDeckSF", "OpenPorchSF", "EnclosedPorch", "3SsnPorch", "ScreenPorch", "PoolArea", "MiscVal", "MoSold", "YrSold", "SalePrice"]
	categorical = ["MSZoning", "Street", "Alley", "LotShape", "LandContour", "Utilities", "LotConfig", "LandSlope", "Neighborhood", "Condition1", "Condition2", "BldgType", "HouseStyle", "RoofStyle", "RoofMatl", "Exterior1st", "Exterior2nd", "MasVnrType", "ExterQual", "ExterCond", "Foundation", "BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1", "BsmtFinType2", "Heating", "HeatingQC", "CentralAir", "Electrical", "KitchenQual", "Functional", "FireplaceQu", "GarageType", "GarageFinish", "GarageQual", "GarageCond", "PavedDrive", "PoolQC", "Fence", "MiscFeature", "SaleType", "SaleCondition"]
	Preset(hierarchical=Dict(),
	       hierarchical_names=String[],
	       numeric=numeric,
	       categorical=String[],
	       numeric_wo_target=setdiff(numeric, [target]),
	       target=target)
end
