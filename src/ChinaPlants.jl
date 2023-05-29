# src/ChinaPlants.jl

module ChinaPlants

export getdbpath

using DataDeps
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

function gettreepath()
	remote_path = plantplus("31bcdfb3-a15d-4d0b-bcc4-682d67d68612")
	name = "ChinaPlants_Tree"
	hash = "d394b32ee868fd711fbcc61ef53013476eb83cb05c8f367b9f7bb2aa219a2ebc"
	path = try
		@datadep_str name
	catch
		register(DataDep(name, 
			"Time tree of plant species in China", remote_path, hash))
		@datadep_str name
	end
	return joinpath(path, "time_tree_13_663sp.tre")
end

end # module ChinaPlants
