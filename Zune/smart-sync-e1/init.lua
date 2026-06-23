local Process = require("@self/../smart-sync/process")
local fs_util = require("@self/../smart-sync/utils")
local json = zune.serde.json
local fs = zune.fs
local stdpath = fs.path

local build_exclusions = {
	["roblox_packages"] = "../roblox_packages",
	["remotes/out/client.luau"] = "../remotes/out/client.luau",
	["remotes/out/server.luau"] = "../remotes/out/server.luau",
	["roblox_server_packages"] = "../roblox_server_packages",
}

local function starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

local function remove(dir)
	if fs_util.exists(dir) then
		fs_util.shell_remove(dir, { recursive = true, force = true })
	end
end

remove("build/global")
remove("build/lobby")

Process.new("rojo")
	:argument("sourcemap")
	:argument("e1.project.json")
	:argument("-o")
	:argument("sourcemap.json")
	:inherit_stdout()
	:run()

Process.new("rojo")
	:argument("sourcemap")
	:argument("e1.project.json")
	:argument("-o")
	:argument("sourcemap.json")
	:argument("--watch")
	:inherit_stdout()
	:spawn()

local darklua =
	Process.new("darklua"):argument("process"):argument("--config"):argument(".darklua.json"):inherit_stdout()

local process_global = darklua:clone():argument("global"):argument("build/global")
process_global:run()

local process_lobby = darklua:clone():argument("lobby"):argument("build/lobby")
process_lobby:run()

local function watch(path, event, prc, out)
	if event == "metadata" then
		return
	end

	local path_in_out = stdpath.join(out, path)
	if event == "created" or event == "modified" then
		local process_this = darklua:clone():argument(path):argument(path_in_out)
		process_this:run()
		return
	end
	if event == "deleted" then
		fs.deleteFile(path_in_out)
		return
	end

	prc:run()
end

fs_util.deep_watch("lobby", function(path, event)
	watch(path, event, process_lobby, "build/")
end)
fs_util.deep_watch("global", function(path, event)
	watch(path, event, process_global, "build/")
end)

local function edit()
	local sync_json = json.decode(fs.readFile("e1.project.json"))
	local function recurse_edit(dir)
		for key, value in dir do
			if key == "$path" then
				if build_exclusions[value] then
					dir["$path"] = build_exclusions[value]
				end
			elseif not starts(key, "$") then
				recurse_edit(dir[key])
			end
		end
	end
	recurse_edit(sync_json.tree)

	fs.writeFile(
		"build/e1.project.json",
		json.encode(sync_json, {
			pretty_indent = 1,
		})
	)
end
edit()
fs_util.watch_file("e1.project.json", function()
	edit()
end)

Process.new("rojo"):argument("serve"):argument("build/e1.project.json"):inherit_stdout():spawn()
