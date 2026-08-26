--!strict
-- Compiles every .luau file that ships in the place, using the same Luau compiler
-- Roblox uses. Catches the class of error that selene and `rojo build` both miss,
-- because neither of them compiles anything:
--
--     GameManager:12831: Out of local registers when trying to allocate
--     WORLD_BROWSER_CACHE_TTL: exceeded limit 200
--
-- That one shipped on main in the "update 28" commit. GameManager owns the whole
-- game, so nothing loaded at all: no life, no UI, no remotes bridge. It was only
-- visible by actually pressing Play.
--
--     just test
--
-- GameManager sits ON the 200 top-level register ceiling. If you add a top-level
-- `local` there, this test fails. Use a script global or a function-local instead.

local fs = zune.fs

local ROOTS = { "game", "global" }

local files: { string } = {}

local function collect(dir: string)
	local entries = fs.entries(dir)
	if type(entries) ~= "table" then return end
	for _, entry in ipairs(entries) do
		local path = dir .. "/" .. entry.name
		if entry.kind == "directory" then
			collect(path)
		elseif string.sub(path, -5) == ".luau" then
			table.insert(files, path)
		end
	end
end

for _, root in ipairs(ROOTS) do
	local info = fs.stat(root)
	if type(info) == "table" and info.kind == "directory" then
		collect(root)
	end
end

table.sort(files)

print("\nLUAU COMPILE")
print("  " .. tostring(#files) .. " files under " .. table.concat(ROOTS, ", "))

local broken: { { path: string, err: string } } = {}

for _, path in ipairs(files) do
	local source = fs.readFile(path)
	local ok, err = pcall(function()
		return zune.luau.compile(source)
	end)
	if not ok then
		table.insert(broken, { path = path, err = tostring(err) })
	end
end

if #broken == 0 then
	print("  ok   every file compiles")
else
	print("")
	for _, failure in ipairs(broken) do
		print("  FAIL " .. failure.path)
		print("       " .. failure.err)
		if string.find(failure.err, "Out of local registers") then
			print("       This file is at Luau's 200 top-level register limit. Drop the")
			print("       `local` keyword to make it a script global, or move the")
			print("       declaration inside the function that uses it.")
		end
	end
	print("")
	error(tostring(#broken) .. " file(s) do not compile", 0)
end
