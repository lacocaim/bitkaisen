-- add-alias.luau

local fs = zune.fs
local process = zune.process

local args = process.args

local alias = args[2]
local path = args[3]

if not alias or not path then
	error("Usage: lune run add-alias.luau <alias> <path>")
end

local function readJson(file)
	local content = fs.readFile(file)
	return zune.serde.json.decode(content)
end

local function writeJson(file, data)
	local content = zune.serde.json.encode(data, {
		pretty_indent = 1,
	}) -- pretty
	fs.writeFile(file, content)
end

local dark = readJson(".darklua.json")
dark.rules[1].current.sources["@" .. alias] = path

writeJson(".darklua.json", dark)

local luaurc = readJson(".luaurc")

luaurc.aliases = luaurc.aliases or {}
luaurc.aliases[alias] = path

writeJson(".luaurc", luaurc)

print(`Added alias "{alias}" -> "{path}"`)
