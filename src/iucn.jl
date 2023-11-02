# src/iucn.jl

export getiucnpath, iucninit, IUCNItem, checkiucn

iucndir = @get_scratch!("iucndir")
iucndict = Dict()

function getiucnpath()
	remote_path = "https://www.mee.gov.cn/xxgk2018/xxgk/xxgk01/" * 
		"202305/W020230522536560832337.pdf"
	name = "ChinaPlants_IUCN"
	hash = "112362ecd0157684ba41d7ed3bc1e9e7d02628b1f2d48e581796b54062354f5c"
	path = try
		@datadep_str name
	catch
		register(DataDep(name, 
			"IUCN Red List of plant species in China", remote_path, hash))
		@datadep_str name
	end
	return joinpath(path, "W020230522536560832337.pdf")
end

function iucninit()
	iucnfile = joinpath(iucndir, "iucndict.jld2")
	if isfile(iucnfile)
		global iucndict = load(iucnfile, "iucndict")
	else
		global iucndict = iucnfileinit()
		save(iucnfile, "iucndict", iucndict)
	end
	return
end

@enum Group begin
	bryophyte=1
	pteridophyte=2
	gymnosperm=3
	angiosperm=4
end

struct IUCNItem
	group::Group
	index::Int
	familyzh::String
	family::String
	taxonzh::String
	taxon::String
	category::String
	criteria::String
	isendemic::Bool
end

function capturefromtexts(texts)
	captures = []
	for (i, text) = enumerate(texts[3:end])
		m = match(r"(中国生物多样性红色名录 ·.{4,8})?\n\d+$", text)
		ind = prevind(text, m.offset)
		lines = split(text[1:ind], '\n')
		j = 1
		while j < length(lines)
			j += 1
			l = lines[j]
			if length(l) == 1 || ! isdigit(l[1]) || occursin(l[2], "abcde√")
				lines[j-1] = lines[j-1] * " " * l
				deleteat!(lines, j)
				j -= 1
			end
		end
		for (j, line) = enumerate(lines)
			m = match(r"^" * 
					r"(\d+) ?" * 
					r"([^\x21-\xff]+) ?" * 
					r"([A-Z][a-z ]+？?) ?" * 
					r"([^\x32-\x5a\x60-\xff]+) ?" * 
					r"([\wA-Za-z- \u00A0\.×\)]+) ?" * 
					r"(EX|EW|RE|DE|CR|EN|VU|NT|LC|DD) ?" * 
					r"([\w（，\.）\(,; +\)\?？]*(-台湾 ?(RL)?)?) ?" * 
					r"(√?)$", line)
			if isnothing(m)
				startswith(line, "序号") || @warn line i j
			else
				push!(captures, m.captures[[1:7; 10]])
			end
		end
	end
	return Matrix{Any}(permutedims(reduce(hcat, captures)))
end

function cleancol(::Val{1}, str::AbstractString)
	nothing === match(r"^\d+$", str) && @warn str
	return parse(Int, str)
end

function cleancol(::Val{2}, str::AbstractString)
	str = filter(!isspace, str)
	nothing === match(r"^[\w（？）]+$", str) && @warn str
	return str
end

function cleancol(::Val{3}, str::AbstractString)
	str = filter(!isspace, str)
	nothing === match(r"^[\w？]+$", str) && @warn str
	return str
end

function cleancol(::Val{4}, str::AbstractString)
	str = filter(!isspace, str)
	str = replace(str, "*"=>"", "-"=>"", "("=>"（", ")"=>"）")
	m = match(r"^(.+)→(.+)$", str)
	if nothing !== m
		str = "$(m.captures[2])（$(m.captures[1])）"
	end
	nothing === match(r"^[\w（、？）\[\]]*$", str) && @warn str
	return str
end

function cleancol(::Val{5}, str::AbstractString)
	str = filter(!=('\u00A0'), str)
	str = replace(str, "f."=>"f. ", "var."=>"var. ", "Subsp."=>"subsp.")
	str = replace(str, r"  +"=>" ")
	str = replace(str, "- "=>"-")
	str = strip(str)
	str == "Cypripedium ×" && (str = "Cypripedium ×ventricosum")
	str == "Heteroscyphus" && (str = "Heteroscyphus acutangulus")
	str == "Nowellia" && (str = "Nowellia aciliata")
	str == "Paulownia ×" && (str = "Paulownia ×taiwaniana")
	str == "Swertia zayü ensis" && (str = "Swertia zayüensis")
	str == "knema linifolia" && (str = "Knema linifolia")
	words = split(str, ' ')
	if !in(get(words, 3, "f."), ["subsp.", "var.", "f."])
		words = words[1:2]
	end
	for i = eachindex(words)[2:end]
		words[i] = lowercase(words[i])
	end
	str = join(words, ' ')
	regex = r"^[A-Z][a-z-ë]+ ×?[a-z-ü]+( (subsp.|var.|f.) [a-z-]+)*$"
	nothing === match(regex, str) && @warn str
	return str
end

function cleancol(::Val{6}, str::AbstractString)
	nothing === match(r"^(EX|EW|RE|DE|CR|EN|VU|NT|LC|DD)$", str) && @warn str
	return str
end

function cleancol(::Val{7}, str::AbstractString)
	str = filter(!isspace, str)
	str = replace(str, 'ⅴ'=>'v', '？'=>'?', '，'=>',', 
		'（'=>'(', '）'=>')', '.'=>',')
	str = replace(str, "3d,D"=>"3d;D", "A3dD1"=>"A3d;D1", 
		"A2c,B1ab(i)"=>"A2c;B1ab(i)")
	str = replace(str, "A1e+A2c"=>"A1e+2c", "B1+B2"=>"B1+2", 
		"A2acd+A3cd"=>"A2acd+3cd", "D1+D2"=>"D1+2", 
		"A1+2+4acd+3cd"=>"A1+2+3cd+4acd", "A1d;A4a"=>"A1d+4a")
	str = replace(str, "B2b(iv)C(iv)"=>"B2b(iv)c(iv)", "Bl"=>"B1")
	str = replace(str, "3c+3d"=>"3cd", "3c+d"=>"3cd", "3a+3c"=>"3ac", 
		"(iii;v)"=>"(iii,v)", "A1c;A1e"=>"A1ce", 
		"B1b(iii)+1c(iv)"=>"B1b(iii)c(iv)", 
		"B1ab(ii,iii,iv,v);C(ii,iii,v)"=>"B1ab(ii,iii,iv,v)c(ii,iii,v)", 
		"A2cd+2cd"=>"A2cd", "B2ac1"=>"B2ac(i)", "A4(e)"=>"A4e", 
		"B2b(ii,iii)C(iv)"=>"B2b(ii,iii)c(iv)")
	str = replace(str, "(iii;v)"=>"(iii,v)", "(iii)(v)"=>"(iii,v)", 
		"(iii+v)"=>"(iii,v)", "(iii;iv)"=>"(iii,iv)")
	str = replace(str, "iiii"=>"iv")
	# checkiucn(str) || @warn str
	return str
end

function cleancol(::Val{8}, str::AbstractString)
	nothing === match(r"^√?$", str) && @warn str
	return str == "√"
end

function checkiucn_a(astr::AbstractString, A::AbstractChar, n::AbstractChar)
	length(astr) == 1 && return true
	a = astr[1]
	astr[2] == '(' && astr[end] == ')' || return false
	res = astr[3:end-1]
	rstrs = split(res, ',')
	romans(i) = ["i", "ii", "iii", "iv", "v"][1:i]
	rcoll = A == 'A' ? romans(5) : 
			A == 'B' ? 
				(a == 'b' ? romans(5) : a == 'c' ? romans(4) : romans(0)) : 
			A == 'C' && n == '2' && a == 'a' ? romans(2) : romans(0)
	return issubset(rstrs, rcoll) && issorted(rstrs; lt=<=)
end

function checkiucn_n(nstr::AbstractString, A::AbstractChar)
	length(nstr) == 0 && return true
	n = nstr[1]
	res = replace(nstr[2:end], r"(?=[abcde])"=>"|")
	isempty(res) && return true
	astrs = split(res, '|')[2:end]
	aa = first.(astrs)
	acoll = A == 'A' ? "abcde" : 
			A == 'B' ? "abc" : 
			A == 'C' && n == '2' ? "ab" : ""
	issubset(aa, acoll) && issorted(aa; lt=<=) || return false
	return all(checkiucn_a.(astrs, A, n))
end

function checkiucn_A(Astr::AbstractString)
	length(Astr) == 1 && return true
	A = Astr[1]
	res = Astr[2:end]
	nstrs = split(res, '+')
	nn = first.(nstrs)
	ncoll = Dict('A'=>"1234", 'B'=>"12", 'C'=>"12", 'D'=>"12", 'E'=>"")[A]
	issubset(nn, ncoll) && issorted(nn; lt=<=) || return false
	return all(checkiucn_n.(nstrs, A))
end

function checkiucn(str::AbstractString)
	isempty(str) && return true
	try
		str = replace(str, "-台湾RL"=>"", "?"=>"")
		Astrs = split(str, ';')
		AA = first.(Astrs)
		issubset(AA, "ABCDE") && issorted(AA; lt=<=) || return false
		return all(checkiucn_A.(Astrs))
	catch
		return false
	end
end

function iucnfileinit()
	path = getiucnpath()
	PyPDF = pyimport("pypdf")
	reader = PyPDF.PdfReader(path)
	f = py"lambda pp: [p.extract_text() for p in pp]"
	@info "Extracting data from file, probably taking several minutes..."
	texts = f(reader.pages)
	table = capturefromtexts(texts)
	for j = 1:8
		table[:, j] .= cleancol.(Val(j), table[:, j])
	end
	groups = Group.(cumsum(table[:, 1] .== 1))
	iucndict = Dict{String, IUCNItem}()
	for i = axes(table, 1)
		name = table[i, 5]
		item = IUCNItem(groups[i], table[i, :]...)
		iucndict[name] = item
	end
	return iucndict
end
