# src/ChinaPlants.jl

module ChinaPlants

export getdbpath, gettreepath, initialize

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

function simplify!(table, headers)
	codes = view(table, :, headers["name_code"])
	acodes = view(table, :, headers["accepted_name_code"])
	@assert allunique(codes)
	@assert issubset(acodes, codes)
	acodeufs = Dict{String, String}()
	for code = codes
		acodeufs[code] = code
	end
	for (code, acode) = zip(codes, acodes)
		acodeufs[code] = acode
	end
	function findroot(acodeufs, code)
		acode = acodeufs[code]
		if acodeufs[acode] != acode
			return acodeufs[code] = acodeufs[acode] = findroot(acodeufs, acode)
		end
		return acode
	end
	for i = eachindex(codes)
		acodes[i] = findroot(acodeufs, codes[i])
	end
	return table
end

function getname2row(table, headers)
	col(str) = view(table, :, headers[str])
	nrow = size(table, 1)
	rels = zeros(nrow)
	rels[getindex.((code2row,), unique(col("accepted_name_code")))] .+= 100
	rels[.!ismissing.(col("species_c"))] .+= 10
	rels[.!startswith.(string.(col("author")), "auct. non")] .+= 1
	name2row = Dict{String, Int}()
	for (i, name) = enumerate(col("canonical_name"))
		(!haskey(name2row, name) || rels[i] > rels[name2row[name]]) && 
			(name2row[name] = i)
	end
	return name2row
end

function initialize()
	xlsx = XLSX.readxlsx(getdbpath())
	sheet = xlsx["scientific_names"][:]
	global headers = Dict(sheet[1, :] .=> axes(sheet, 2))
	global table = sheet[2:end, :]
	col(str) = view(table, :, headers[str])
	codes = col("name_code")
	global code2row = Dict(codes .=> eachindex(codes))
	col("accepted_name_code")[col("name_code") .== "T20171000078632"] .= 
		"T20211000001316" # special patch for v1.043 (2023)
	simplify!(table, headers)
	arows = sort!(getindex.((code2row,), unique(col("accepted_name_code"))))
	@assert findall(col("name_code") .== col("accepted_name_code")) == arows
	global name2row = getname2row(table, headers)
	@assert issubset(arows, values(name2row))
end

end # module ChinaPlants
