local vide = require("@packages/vide")

local source = vide.source

type Route = string
type ModalEntry = {
	id: string,
	route: Route,
}

local activeRoute = source("" :: Route)
local modalStack = source({} :: { ModalEntry })
local topBarVisible = source(true)

local subscribers = {} :: { (route: Route) -> () }

local function notifySubscribers()
	local route = activeRoute()
	for _, fn in subscribers do
		task.spawn(fn, route)
	end
end

local function subscribe(fn: (route: Route) -> ()): () -> ()
	table.insert(subscribers, fn)
	local idx = #subscribers
	return function()
		for i, sub in subscribers do
			if sub == fn then
				table.remove(subscribers, i)
				return
			end
		end
	end
end

local function hasModal()
	return #modalStack() > 0
end

local function topModal()
	local stack = modalStack()
	if #stack == 0 then return nil end
	return stack[#stack]
end

local function navigate(route: Route)
	if activeRoute() == route then
		activeRoute("")
		notifySubscribers()
		return
	end
	modalStack({})
	activeRoute(route)
	notifySubscribers()
end

local function closeRoute()
	activeRoute("")
	modalStack({})
	notifySubscribers()
end

local function pushModal(id: string, route: Route)
	local stack = table.clone(modalStack())
	for i, entry in stack do
		if entry.id == id then
			table.remove(stack, i)
			break
		end
	end
	table.insert(stack, { id = id, route = route })
	modalStack(stack)
end

local function popModal(): ModalEntry?
	local stack = table.clone(modalStack())
	if #stack == 0 then return nil end
	local entry = table.remove(stack)
	modalStack(stack)
	return entry
end

local function closeModal(id: string)
	local stack = table.clone(modalStack())
	for i, entry in stack do
		if entry.id == id then
			table.remove(stack, i)
			modalStack(stack)
			return
		end
	end
end

local function closeAll()
	activeRoute("")
	modalStack({})
	notifySubscribers()
end

return {
	activeRoute = activeRoute,
	modalStack = modalStack,
	topBarVisible = topBarVisible,
	hasModal = hasModal,
	topModal = topModal,

	navigate = navigate,
	closeRoute = closeRoute,
	pushModal = pushModal,
	popModal = popModal,
	closeModal = closeModal,
	closeAll = closeAll,
	subscribe = subscribe,
}
