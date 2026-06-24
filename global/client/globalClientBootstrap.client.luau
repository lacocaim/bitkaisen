local ReplicatedStorage = game:GetService("ReplicatedStorage")

local globalClient = require(ReplicatedStorage:WaitForChild("global"):WaitForChild("client"))

globalClient.init()
