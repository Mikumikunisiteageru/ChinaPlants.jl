# test/runtests.jl

using ChinaPlants
using Test

const CP = ChinaPlants

@testset "iucn" begin
	@test isempty(ChinaPlants.iucndict)
	@test nothing === iucninit()
	@test length(ChinaPlants.iucndict) == 39320		
end

@testset "standardize" begin
	@test CP.cpcode("Allium tui") == "T20171000044079"
	@test CP.cpcode("Allium cyaneum") == "T20171000044077"
	@test CP.cpaccode("Allium tui") == "T20171000044077"
	@test CP.cpaccode("Allium cyaneum") == "T20171000044077"
	@test standardize("Allium kepa"; showlog=false) == "Allium cepa"
	@test standardize("Allium tui"; showlog=false) == "Allium cyaneum"
	@test standardize("Allium wallichii"; showlog=false) == "Allium wallichii"
end
