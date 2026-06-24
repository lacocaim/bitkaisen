local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

return {
	Value = Fusion.Value,
	Computed = Fusion.Computed,
	Hydrate = Fusion.Hydrate,
	Observer = Fusion.Observer,
	Spring = Fusion.Spring,
	Tween = Fusion.Tween,
	New = Fusion.New,
	Children = Fusion.Children,
	OnEvent = Fusion.OnEvent,
	OnChange = Fusion.OnChange,
	Fusion = Fusion,
}
