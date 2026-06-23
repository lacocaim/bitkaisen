local process = zune.process
local task = zune.task

local Process = {}
local mt = { __index = Process }

type Properties = {
	command: string,
	args: { string },
	options: ProcessOptions,
}
export type Identity = typeof(setmetatable({} :: Properties, {} :: typeof(mt)))

local function constructor(command: string): Identity
	local self: Properties = {
		command = command,
		args = {},
		options = {},
	}

	return setmetatable(self, mt)
end

function Process.argument(self: Identity, argument: string): Identity
	table.insert(self.args, argument)
	return self
end

function Process.option(self: Identity, option: any, value: any): Identity
	(self.options :: any)[option] = value
	return self
end

function Process.inherit_stdout(self: Identity): Identity
	return self:option("stdout", "inherit"):option("stderr", "inherit")
end

function Process.create(self: Identity): ProcessChild
	return process.create(self.command, self.args, self.options)
end

function Process.run(self: Identity, carry_exit: boolean?)
	local result = process.run(self.command, self.args, self.options)
	if not result.ok and (carry_exit == nil or carry_exit == true) then
		error(result.code)
	end
	return result
end

function Process.spawn(self: Identity): thread
	return task.spawn(process.run, self.command, self.args, self.options)
end

function Process.clone(self: Identity): Identity
	local clone: Properties = {
		command = self.command,
		args = table.clone(self.args),
		options = table.clone(self.options),
	}

	return setmetatable(clone, mt)
end

return {
	new = constructor,
}
