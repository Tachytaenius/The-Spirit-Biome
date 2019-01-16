local constants = require("constants")

local hc = require("lib.hc++")
local concord = require("lib.concord")

local components = require("components")
local systems = require("systems")

return function(x, y, width, height)
	local new = concord.instance()
	new.collider = hc.new(constants.gameplay.cellSize)
	new:addSystem(systems.movement(), "fixedUpdate")
	-- new:addSystem("update")
	new:addSystem(systems.movement(), "draw")
	local entity = concord.entity():give(components.position, 50, 50, 0):give(components.player, 1):give(components.mobility, 16, 32, 12,  14, 28, 10, math.tau * 2, math.tau * 2, math.tau / 2)
	new:addEntity(entity)
	new:addEntity(concord.entity():give(components.position, 50, 50, 0):give(components.ai, entity, 16, 4):give(components.mobility, 15, 31, 11,  13, 27, 9, math.tau * 2, math.tau * 2, math.tau / 2))
	return new
end

