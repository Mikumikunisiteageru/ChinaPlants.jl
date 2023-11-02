# src/ChinaPlants.jl

module ChinaPlants

export getdbpath, checkspell, forceaccept, standardize, standardize!
export getprop, getkingdom, getphylum, getclass, getorder, getfamily, getgenus
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

include("database.jl")
include("tree.jl")
include("iucn.jl")

end # module ChinaPlants
