# test/runtests.jl

using ChinaPlants
using Test

@test isempty(ChinaPlants.iucndict)

@test nothing === iucninit()

@test length(ChinaPlants.iucndict) == 39320
