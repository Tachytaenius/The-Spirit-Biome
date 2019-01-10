math = require("lib.mathsies")
local constants = require("constants")

function love.conf(t)
	t.identity = constants.core.identity
	t.version = "11.2"
	t.accelorometerjoystick = false
	t.appendidentity = true
	
	t.window.title = constants.core.title
	t.window.icon = "icon.png"
	t.window.width = constants.graphics.width
	t.window.height = constants.graphics.height
end
