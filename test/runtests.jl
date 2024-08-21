# test/runtests.jl

using Aqua
using ChinaPlants
using Test

# Aqua.test_ambiguities([ChinaPlants, Base, Core])
Aqua.test_unbound_args(ChinaPlants)
Aqua.test_undefined_exports(ChinaPlants)
Aqua.test_piracy(ChinaPlants)
Aqua.test_project_extras(ChinaPlants)
Aqua.test_stale_deps(ChinaPlants)
Aqua.test_deps_compat(ChinaPlants)
Aqua.test_project_toml_formatting(ChinaPlants)

const CP = ChinaPlants

@testset "database" begin
	@test last(splitpath(getdbpath())) == "sp2000-2024_植物完整版V1.03.xlsx"
	@test CP.cpcode("Allium tui") == "T20171000044079"
	@test CP.cpcode("Allium cyaneum") == "T20171000044077"
	@test CP.cpaccode("Allium tui") == "T20171000044077"
	@test CP.cpaccode("Allium cyaneum") == "T20171000044077"
	@test standardize("Allium kepa"; showlog=false) == "Allium cepa"
	@test standardize("Allium tui"; showlog=false) == "Allium cyaneum"
	@test standardize("Allium wallichii"; showlog=false) == "Allium wallichii"
	@test_skip getkingdom("Milula spicata") == "Plantae"
	@test getphylum("Milula spicata") == "Tracheophyta"
	@test getclass("Milula spicata") == "Magnoliopsida"
	@test_skip getorder("Milula spicata") == "Asparagales"
	@test getfamily("Milula spicata") == "Amaryllidaceae"
	@test getgenus("Milula spicata") == "Allium"
	@test getlitgenus("Milula spicata") == "Milula"
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
