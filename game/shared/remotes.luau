local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Packages.Bytenet)

return ByteNet.DefineNamespace("Replication", function()
	return {
		ReliableUpdates = ByteNet.DefinePacket({
			ReliabilityType = "Reliable",
			Value = ByteNet.Struct({
				buf = ByteNet.Buff,
				variants = ByteNet.Array(ByteNet.Array(ByteNet.Unknown)),
			}),
		}),

		UnreliableUpdates = ByteNet.DefinePacket({
			ReliabilityType = "Unreliable",
			Value = ByteNet.Struct({
				buf = ByteNet.Buff,
				variants = ByteNet.Array(ByteNet.Array(ByteNet.Unknown)),
			}),
		}),

		RequestSnapshot = ByteNet.DefinePacket({
			ReliabilityType = "Reliable",
			Value = ByteNet.Nothing,
		}),

		Snapshot = ByteNet.DefinePacket({
			ReliabilityType = "Reliable",
			Value = ByteNet.Struct({
				buf = ByteNet.Buff,
				variants = ByteNet.Array(ByteNet.Array(ByteNet.Unknown)),
			}),
		}),
	}
end)
