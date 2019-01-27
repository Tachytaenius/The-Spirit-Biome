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
			advance = 80,
			backpedal = 70,
			strafeLeft = 75,
			strafeRight = 75,
			turnLeft = math.tau * 0.5,
			turnRight = math.tau * 0.5
		},
		{
			advance = 150,
			backpedal = 140,
			strafeLeft = 145,
			strafeRight = 145,
			turnLeft = math.tau * 2,
			turnRight = math.tau * 2
		},
		{
			advance = 200,
			backpedal = 290,
			strafeLeft = 295,
			strafeRight = 295,
			turnLeft = math.tau * 3,
			turnRight = math.tau * 3
		}
	)
	new:addEntity(entity)
	return new
end

