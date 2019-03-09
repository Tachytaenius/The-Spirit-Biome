local constants = require("constants")
local settings = require("settings")
local components = require("components")
local vision = require("lib.concord.system")(
	{"seers", components.ai, components.sight},
	{"presences", components.presence}
)

function vision:draw(lerp, entity)
	if not entity then return end
	assert(self:getInstance().entities:has(entity), "Emitted draw into the wrong instance; it should contain the camera entity")
	
	local function angle(previous, current)
		return previous + math.angleDifference(current, previous) * lerp
	end
	
	local function ordinate(previous, current)
		return current * lerp + previous * (1 - lerp)
	end
	
	local function doPresence(presence)
		local presenceX, presenceY, presenceTheta = presence.x, presence.y, presence.theta
		if settings.graphics.interpolation then
			presenceX = ordinate(presence.previousX, presenceX)
			presenceY = ordinate(presence.previousY, presenceY)
			presenceTheta = angle(presence.previousTheta, presenceTheta)
		end
		return presenceX, presenceY, presenceTheta
	end
	
	local seerPresence = entity:get(components.presence)
	local seerX, seerY, seerTheta = doPresence(seerPresence)
	love.graphics.translate(constants.graphics.width / 2, constants.graphics.height)
	love.graphics.rotate(-seerTheta)
	love.graphics.translate(seerX, seerY)
	
	
	
	love.graphics.origin()
end

return vision
