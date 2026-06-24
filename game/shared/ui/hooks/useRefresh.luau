local vide = require("@packages/vide")
local setTimeout = require("./setTimeout")

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Source<T> = () -> T

return function<T, Obj>(component: (...T) -> (Obj, number)): ((...T) -> (), Source<Array<Obj>>)
	local scopes = {} :: Map<number, {
		destroy: () -> (),
		object: Obj,
		cancel: (() -> ())?,
	}>
	local output = vide.source({} :: Array<Obj>)
	local function update_output()
		local objects = {}
		for _, scope in scopes do
			table.insert(objects, scope.object)
		end
		output(objects)
	end

	vide.cleanup(function()
		for value, scope in scopes do
			if scope.cancel then
				scope.cancel()
			end
			scope.destroy()
		end
	end)

	return function(...)
		local args = { ... }

		local _delay: number
		local destroy, object = vide.root(function()
			local object, t = component(unpack(args))
			_delay = t
			return object
		end)
		if not _delay then
			destroy()
			error("Delay not specified, destroying scope.")
		end

		local index = #scopes + 1
		scopes[index] = {
			destroy = destroy,
			object = object,
			cancel = setTimeout(function()
				if scopes[index] then
					scopes[index].destroy()
					scopes[index] = nil
					update_output()
				end
			end, _delay),
		}

		update_output()
	end, output
end
