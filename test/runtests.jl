# test/runtests.jl

using ChinaPlants
using Test

const CP = ChinaPlants

@testset "database" begin
	@test last(splitpath(getdbpath())) == "Sp2000cn-2023 植物完整版含简表 v1.043.xlsx"
	@test CP.cpcode("Allium tui") == "T20171000044079"
	@test CP.cpcode("Allium cyaneum") == "T20171000044077"
	@test CP.cpaccode("Allium tui") == "T20171000044077"
	@test CP.cpaccode("Allium cyaneum") == "T20171000044077"
	@test standardize("Allium kepa"; showlog=false) == "Allium cepa"
	@test standardize("Allium tui"; showlog=false) == "Allium cyaneum"
	@test standardize("Allium wallichii"; showlog=false) == "Allium wallichii"
	@test getkingdom("Milula spicata") == "Plantae"
	@test getphylum("Milula spicata") == "Tracheophyta"
	@test getclass("Milula spicata") == "Magnoliopsida"
	@test getorder("Milula spicata") == "Asparagales"
	@test getfamily("Milula spicata") == "Amaryllidaceae"
	@test getgenus("Milula spicata") == "Allium"
	@test getprop("Milula spicata", "author") == "(Prain) N. Friesen"
end

@testset "tree" begin
	@test last(splitpath(gettreepath())) == "time_tree_13_663sp.tre"
end

@testset "iucn" begin
	@test isempty(ChinaPlants.iucndict)
	@test nothing === iucninit()
	@test length(ChinaPlants.iucndict) == 39320		
end
