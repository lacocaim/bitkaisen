local vide = require("@packages/vide")

return function(connection, fn: () -> ())
	vide.cleanup(connection:Connect(fn))
end
