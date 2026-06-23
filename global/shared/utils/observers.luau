local Players = game:GetService("Players")

local function observePlayers(callback: (player: Player) -> (() -> ())?)
	local cleanups = {}

	local function onAdded(player: Player)
		local cleanup = callback(player)
		if cleanup then
			cleanups[player] = cleanup
		end
	end

	local function onRemoved(player: Player)
		local cleanup = cleanups[player]
		if cleanup then
			cleanup()
			cleanups[player] = nil
		end
	end

	Players.PlayerAdded:Connect(onAdded)
	Players.PlayerRemoving:Connect(onRemoved)

	for _, player in Players:GetPlayers() do
		task.spawn(onAdded, player)
	end

	return function()
		Players.PlayerAdded:Connect(onAdded):Disconnect()
		Players.PlayerRemoving:Connect(onRemoved):Disconnect()
		for player, cleanup in cleanups do
			cleanup()
			cleanups[player] = nil
		end
	end
end

return {
	observePlayers = observePlayers,
}
