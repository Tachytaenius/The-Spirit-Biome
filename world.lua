local constants = require("constants")

local hc = require("lib.hc")
local concord = require("lib.concord")

local components = require("components")
local systems = require("systems")

return function(x, y, width, height, rng, dayLength, time)
	local new = concord.instance()
	new.collider = hc.new(constants.gameplay.cellSize)
	new.hasLerpValues = false
	new.x, new.y, new.width, new.height = x, y, width, height
	new.rng = rng -- All worlds have a copy of the RNG so that they can allow their systems access to it via getInstance()
	new.dayLength = length
	new.time = time
	
	local vision = systems.vision()
	local movement = systems.movement()
	
	new:addSystem(movement, "copyLerpValues")
	
	new:addSystem(movement, "clearLerpValues")
	
	-- new:addSystem(vision, "execute")
	new:addSystem(movement, "execute")
	
	new:addSystem(movement, "correct")
	
	new:addSystem(movement, "draw")
	-- new:addSystem(vision, "draw")
	
	return new
end
