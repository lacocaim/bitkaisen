local RunService = game:GetService("RunService")

function setTimeout(callback: () -> (), timeout: number)
	local start = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if (os.clock() - start) > timeout then
			callback()
			conn:Disconnect()
		end
	end)
	return function()
		if conn.Connected then
			conn:Disconnect()
		end
	end
end

return setTimeout
