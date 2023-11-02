# src/database.jl

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

dbpath = @get_scratch!("database")
dbscratch(file::AbstractString) = joinpath(dbpath, file)

function simplify!(table, headers)
	codes = view(table, :, headers["name_code"])
	accodes = view(table, :, headers["accepted_name_code"])
	@assert allunique(codes)
	@assert issubset(accodes, codes)
	acodeufs = Dict{String, String}()
	for code = codes
		acodeufs[code] = code
	end
	for (code, acode) = zip(codes, accodes)
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
		accodes[i] = findroot(acodeufs, codes[i])
	end
	return table
end

function getname2row(table, headers, code2row)
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

struct Table
	headers
	table
	code2row
	name2row
end

function buildsyns(xlsx)
	sheet = xlsx["scientific_names"][:]
	headers = Dict(sheet[1, :] .=> axes(sheet, 2))
	table = sheet[2:end, :]
	col(str) = view(table, :, headers[str])
	codes = col("name_code")
	code2row = Dict(codes .=> eachindex(codes))
	col("accepted_name_code")[col("name_code") .== "T20171000078632"] .= 
		"T20211000001316" # specific patch for v1.043 (2023)
	simplify!(table, headers)
	arows = sort!(getindex.((code2row,), unique(col("accepted_name_code"))))
	@assert findall(col("name_code") .== col("accepted_name_code")) == arows
	name2row = getname2row(table, headers, code2row)
	@assert issubset(arows, values(name2row))
	return Table(headers, table, code2row, name2row)
end

function buildprops(xlsx)
	sheet = xlsx["scientific_names-物种接受名简表"][:]
	headers = Dict(sheet[1, :] .=> axes(sheet, 2))
	table = sheet[2:end, :]
	col(str) = view(table, :, headers[str])
	codes = col("name_code")
	code2row = Dict(codes .=> eachindex(codes))
	names = col("canonical_name")
	name2row = Dict(names .=> eachindex(names))
	return Table(headers, table, code2row, name2row)
end

function initialize()
	@info("Initializing... May take up to one minute...")
	xlsx = XLSX.readxlsx(getdbpath())
	syns = buildsyns(xlsx)
	props = buildprops(xlsx)
	save_object(dbscratch("syns.jld2"), syns)
	save_object(dbscratch("props.jld2"), props)
	return (syns=syns, props=props)
end

function cpsyns()
	(@isdefined syns) && return syns
	synspath = dbscratch("syns.jld2")
	return global syns = 
		isfile(synspath) ? load_object(synspath) : initialize().syns
end

function cpprops()
	(@isdefined props) && return props
	propspath = dbscratch("props.jld2")
	return global props = 
		isfile(propspath) ? load_object(propspath) : initialize().props
end

function getprop(name::AbstractString, prop::AbstractString; 
		showlog=false, spellchecks=false)
	props = cpprops()
	col(str) = view(props.table, :, props.headers[str])
	spellchecks && (name = checkspell(name; showlog=showlog))
	accode = cpaccode(name)
	return col(prop)[props.code2row[accode]]
end
getkingdom(name::AbstractString; kwargs...) = 
	getprop(name, "kingdom"; kwargs...)
getphylum(name::AbstractString; kwargs...) = getprop(name, "phylum"; kwargs...)
getclass(name::AbstractString; kwargs...) = getprop(name, "class"; kwargs...)
getorder(name::AbstractString; kwargs...) = getprop(name, "order"; kwargs...)
getfamily(name::AbstractString; kwargs...) = getprop(name, "family"; kwargs...)
getgenus(name::AbstractString; kwargs...) = getprop(name, "genus"; kwargs...)

function cpssc()
	(@isdefined ssc) && return ssc
	syns = cpsyns()
	@info("Indexing names... May take several seconds...")
	global ssc = SymSpell(; max_dictionary_edit_distance=3)
	for name = keys(syns.name2row)
		push!(ssc, name)
	end
	set_options!(ssc; verbosity=SymSpellChecker.VerbosityCLOSEST)
	return ssc
end

function checkspell(rawname::AbstractString; showlog=true)
	candidates = cpssc()[rawname]
	showlog && @info("candidates: $(join(candidates, ", "))")
	isempty(candidates) && throw(KeyError(rawname))
	okname = first(candidates)
	showlog && @info("candidate $okname applied")
	return okname
end

function cpcode(name::AbstractString)
	syns = cpsyns()
	col(str) = view(syns.table, :, syns.headers[str])
	return col("name_code")[syns.name2row[name]]
end

function cpaccode(synonym::AbstractString)
	syns = cpsyns()
	col(str) = view(syns.table, :, syns.headers[str])
	return col("accepted_name_code")[syns.name2row[synonym]]
end

function forceaccept(synonym::AbstractString)
	syns = cpsyns()
	col(str) = view(syns.table, :, syns.headers[str])
	accode = cpaccode(synonym)
	row = syns.code2row[accode]
	return col("canonical_name")[row]
end

function standardize(name::AbstractString; 
		showlog=true, spellchecks=true, acceptforces=true)
	spellchecks && (name = checkspell(name; showlog=showlog))
	acceptforces && (name = forceaccept(name))
	return name
end

function standardize!(namevec::AbstractVector{<:AbstractString}; 
		showlog=true, forceaccept=true, symspell=true)
	unmatched = falses(length(namevec))
	for i = eachindex(namevec)
		try
			namevec[i] = standardize(namevec[i]; 
				showlog=false, forceaccept=forceaccept, symspell=symspell)
		catch KeyError
			unmatched[i] = true
		end
	end
	showlog && 
		@info("unmatched items include $(join(findall(unmatched), ","))")
	return namevec
end

function standardize(namevec::AbstractVector{<:AbstractString}; 
		showlog=true, forceaccept=true, symspell=true)
	return standardize!(deepcopy(namevec); 
		showlog=showlog, forceaccept=forceaccept, symspell=symspell)
end
