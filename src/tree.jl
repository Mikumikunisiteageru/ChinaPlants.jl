# src/tree.jl

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

