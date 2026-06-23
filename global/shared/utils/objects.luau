local function deepFreeze<T>(t: T & {}): T
	table.freeze(t)
	for _, v in t do
		if type(v) == "table" and not table.isfrozen(v) then
			deepFreeze(v)
		end
	end
	return t
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
	set = set,
	delete = delete,
}
