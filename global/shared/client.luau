local accountController = require("@global/shared/controllers/accountController")
local commandController = require("@global/shared/controllers/commandController")
return {
	init = function()
		accountController.init()
		commandController.init()
	end,
}
