# src/ChinaPlants.jl

module ChinaPlants

export getdbpath, checkspell, forceaccept, standardize
export gettreepath
export iucninit

using DataDeps
using FileIO
using JLD2
using PyCall
using Scratch
using SymSpellChecker
using XLSX

function __init__()
	ENV["DATADEPS_ALWAYS_ACCEPT"] = true
end

function plantplus(guid)
	return "https://www.plantplus.cn/cn/datasetdatadown?guid=$guid"
end

function getdbpath()
	remote_path = plantplus("e35f34dd-a2c1-4c00-9382-142020a6e04f")
	name = "ChinaPlants"
	hash = "d26f17c38478d8a8d43de71fecfff9e1b2db50b838e6d29262a59e1bd1f22a77"
	path = try
		@datadep_str name
	catch
		register(DataDep(name, 
			"Checklist of plant species in China", remote_path, hash))
		@datadep_str name
	end
	return joinpath(path, "Sp2000cn-2023 植物完整版含简表 v1.043.xlsx")
end

include("database.jl")
include("tree.jl")
include("iucn.jl")

end # module ChinaPlants
