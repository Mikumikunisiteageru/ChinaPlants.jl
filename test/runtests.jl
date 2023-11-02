# test/runtests.jl

using ChinaPlants
using Test

@testset "iucn" begin
	@test isempty(ChinaPlants.iucndict)
	@test nothing === iucninit()
	@test length(ChinaPlants.iucndict) == 39320		
end

@testset "checkspell" begin
	@test checkspell("Allium kepa") == "Allium cepa"
	@test checkspell("Allium tui") == "Allium cyaneum"
end
