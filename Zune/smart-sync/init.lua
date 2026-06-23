local Process = require("@self/process")
local fs_util = require("@self/utils")
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

local function smart_sync(name)
	remove("build/global")
	remove(`build/{name}`)

	Process.new("rojo")
		:argument("sourcemap")
		:argument(`{name}.project.json`)
		:argument("-o")
		:argument("sourcemap.json")
		:argument("--watch")
		:inherit_stdout()
		:spawn()

	local darklua =
		Process.new("darklua"):argument("process"):argument("--config"):argument(".darklua.json"):inherit_stdout()

	local process_global = darklua:clone():argument("global"):argument("build/global")
	process_global:run()

	local process_project = darklua:clone():argument(name):argument("build/" .. name)
	process_project:run()

	local function watch(path, event, prc, out)
		if event == "metadata" then
			return
		end

		local path_in_out = stdpath.join(out, path)
		if event == "created" or event == "modified" then
			if event == "created" then
			end

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

	fs_util.deep_watch(name, function(path, event)
		watch(path, event, process_project, "build/")
	end)
	fs_util.deep_watch("global", function(path, event)
		watch(path, event, process_global, "build/")
	end)
	local function edit()
		local sync_json = json.decode(fs.readFile(`{name}.project.json`))
		local function recurse_edit(dir)
			for key, value in dir do
				if key == "$path" then
					if build_exclusions[value] then
						dir["$path"] = build_exclusions[value]
						-- else
						-- 	dir["$path"] = "build/" .. value
					end
				elseif not starts(key, "$") then
					recurse_edit(dir[key])
				end
			end
		end
		recurse_edit(sync_json.tree)

		fs.writeFile(
			`build/{name}.project.json`,
			json.encode(sync_json, {
				pretty_indent = 1,
			})
		)
	end
	edit()
	fs_util.watch_file(`{name}.project.json`, function(m)
		edit()
	end)

	Process.new("rojo"):argument("serve"):argument(`build/{name}.project.json`):inherit_stdout():spawn()
end

smart_sync(zune.process.args[2])
return smart_sync
