local constants = require("constants")

local hc = require("lib.hc")
local concord = require("lib.concord")

local components = require("components")
local systems = require("systems")

return function(x, y, width, height)
	local new = concord.instance()
	new.collider = hc.new(constants.gameplay.cellSize)
	
	
	
	
	
	
	local movement = systems.movement()
	
	new:addSystem(movement, "execute")
	new:addSystem(movement, "correct")
	new:addSystem(movement, "draw")
	
	
	
	
	
	
	local entity = concord.entity():give(components.presence, 0, 0, 0, {}, {}):give(components.player, 1):give(components.velocity):give(
		components.mobility,
		{
			advance = 12,
			backpedal = 9,
			strafeLeft = 10,
			strafeRight = 10,
			turnLeft = math.tau * 0.5,
			turnRight = math.tau * 0.5
		},
		{
			advance = 16,
			backpedal = 13,
			strafeLeft = 14,
			strafeRight = 14,
			turnLeft = math.tau * 2,
			turnRight = math.tau * 2
		},
		{
			advance = 32,
			backpedal = 24,
			strafeLeft = 28,
			strafeRight = 28,
			turnLeft = math.tau * 2,
			turnRight = math.tau * 2
		}
	)
	new:addEntity(entity)
	return new
end

