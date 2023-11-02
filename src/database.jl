# src/database.jl

dbpath = @get_scratch!("database")
dbscratch(file::AbstractString) = joinpath(dbpath, file)

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

function cpdata()
	(@isdefined data) && return data
	path = dbscratch("data.jld2")
	isfile(path) && return global data = load_object(path)
	@info("Initializing... May take up to one minute...")
	xlsx = XLSX.readxlsx(getdbpath())
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
	global data = (headers=headers, table=table, 
		code2row=code2row, name2row=name2row)
	save_object(path, data)
	return data
end

function cpssc()
	(@isdefined ssc) && return ssc
	data = cpdata()
	@info("Indexing names... May take several seconds...")
	global ssc = SymSpell(; max_dictionary_edit_distance=3)
	for name = keys(data.name2row)
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
	data = cpdata()
	col(str) = view(data.table, :, data.headers[str])
	return col("name_code")[data.name2row[name]]
end

function cpaccode(synonym::AbstractString)
	data = cpdata()
	col(str) = view(data.table, :, data.headers[str])
	return col("accepted_name_code")[data.name2row[synonym]]
end

function forceaccept(synonym::AbstractString)
	data = cpdata()
	col(str) = view(data.table, :, data.headers[str])
	accode = cpaccode(synonym)
	row = data.code2row[accode]
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
