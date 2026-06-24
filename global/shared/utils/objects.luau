local function deepFreeze<T>(t: T & {}): T
	table.freeze(t)
	for _, v in t do
		if type(v) == "table" and not table.isfrozen(v) then
			deepFreeze(v)
		end
	end
	return t
end

local function deepClone(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local clone = table.clone(t)
	for k, v in clone do
		if type(v) == "table" then
			clone[k] = deepClone(v)
		end
	end
	return clone
end

local function set<K, V>(t: { [K]: V }, key: K, value: V): { [K]: V }
	local new = table.clone(t)
	new[key] = value
	return new
end

local function delete<K, V>(t: { [K]: V }, key: K): { [K]: V }
	local new = table.clone(t)
	new[key] = nil
	return new
end

return {
	deepFreeze = deepFreeze,
	deepClone = deepClone,
	set = set,
	delete = delete,
}
