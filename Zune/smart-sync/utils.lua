local fs = zune.fs
local task = zune.task
local process = zune.process
local platform = zune.platform
local stdpath = fs.path

local function exists(path: string): boolean
	return fs.stat(path).kind ~= "none"
end

local function shell_remove(path: string, flags: { recursive: boolean?, force: boolean? }?)
	local args = table.create(3)
	if flags then
		if flags.recursive then
			table.insert(args, "-r")
		end

		if flags.force then
			table.insert(args, if platform.os == "windows" then "-Force" else "-f")
		end
	end
	table.insert(args, path)
	process.run("rm", args, { shell = if platform.os == "windows" then "powershell" else "bash" })
end

local function watch_file(path: string, fn: (metadata: Metadata) -> ()): () -> ()
	local origin_metadata = fs.metadata(path)
	local last_modified = origin_metadata.modified_at
	local thread = task.spawn(function()
		while true do
			task.wait(1)

			local metadata = fs.metadata(path)
			if last_modified < metadata.modified_at then
				last_modified = metadata.modified_at
				fn(metadata)
			end
		end
	end)

	return function()
		task.cancel(thread)
	end
end

type WatchEvent = "created" | "modified" | "moved" | "renamed" | "deleted" | "metadata"
local function deep_watch(path: string, fn: (path: string, event: WatchEvent) -> ()): () -> ()
	local dtors = {}

	local last_modified: { path: string, at: number }? = nil
	local watcher = fs.watch(path, function(child_name, events)
		local event_path = stdpath.join(path, child_name)

		if table.find(events, "modified") then
			local metadata = fs.metadata(event_path)

			if last_modified and last_modified.at == metadata.modified_at and last_modified.path == event_path then
				return
			end
			last_modified = { path = event_path, at = metadata.modified_at }
		end

		if table.find(events, "deleted") or table.find(events, "moved") or table.find(events, "renamed") then
			local dtor = dtors[event_path]
			if dtor then
				dtor()
				dtors[event_path] = nil
			elseif fs.stat(event_path).kind == "directory" then
				dtors[event_path] = deep_watch(event_path, fn)
			end
		end

		if table.find(events, "created") and fs.stat(event_path).kind == "directory" then
			dtors[event_path] = deep_watch(event_path, fn)
		end

		for _, event in events do
			fn(event_path, event :: WatchEvent)
		end
	end)

	local function root_dtor()
		watcher:stop()
	end
	dtors[path] = root_dtor

	for _, entry in fs.entries(path) do
		if entry.kind ~= "directory" then
			continue
		end

		local child_path = stdpath.join(path, entry.name)
		dtors[child_path] = deep_watch(child_path, fn)
	end

	return function()
		for _, dtor in dtors do
			dtor()
		end

		dtors = {}
	end
end

return {
	exists = exists,
	shell_remove = shell_remove,
	watch_file = watch_file,
	deep_watch = deep_watch,
}
