local input = require("input")
local constants = require("constants")
local components = require("components")
local movement = require("lib.concord.system")(
	{"mobs", components.presence, components.velocity, components.mobility}
)

local terrain = {{}, {}, {}}
for _, terrain in pairs(terrain) do
	for _=1, 7998 do
		table.insert(terrain, (math.ndRandom() - 0.5) * 1500)
	end
end

function movement:draw(lag)
	for i = 1, self.mobs.size do
		local sooch = self.mobs:get(i):get(components.presence)
		love.graphics.translate(constants.graphics.width / 2, constants.graphics.height - 80)
		love.graphics.rotate(-sooch.theta)
		love.graphics.translate(-sooch.x, -sooch.y)
		love.graphics.setPointSize(1)
		love.graphics.setColor(1, 0, 0)
		love.graphics.points(unpack(terrain[1]))
		love.graphics.setColor(0, 1, 0)
		love.graphics.points(unpack(terrain[2]))
		love.graphics.setColor(0, 0, 1)
		love.graphics.points(unpack(terrain[3]))
		love.graphics.setPointSize(3)
		love.graphics.setColor(1, 1, 1)
		love.graphics.points(sooch.x, sooch.y)
		love.graphics.origin()
	end
end

local movementCommandsToCheck = {
	advance = true,
	strafeLeft = true,
	backpedal = true,
	strafeRight = true,
	turnLeft = true,
	turnRight = true,
	run = true,
	sneak = true
}

function movement:execute(dt)
	for i = 1, self.mobs.size do
		local entity = self.mobs:get(i)
		
		local commands = {}
		do -- Get commands
			local ai = entity:get(components.ai)
			local player = entity:get(components.player)
			
			if ai then
				-- TODO
			else
				for command in pairs(movementCommandsToCheck) do
					commands[command] = input.checkFixedUpdateCommand(command)
				end
			end
		end
		
		-- Get speed multiplier
		local speedMultiplier
		if commands.sneak and not commands.run then
			speedMultiplier = 0.25
		elseif not commands.run then
			speedMultiplier = 0.5
		else
			speedMultiplier = 1
		end
		
		local mobility = entity:get(components.mobility)
		local velocity = entity:get(components.velocity)
		
		-- Abstraction for getting target velocity and change (acceleration/deceleration)
		local function getVelocities(negative, positive, current)
			-- TODO: optimise writing
			local target, change
			if commands[negative] and not commands[positive] then
				target = -mobility.maxTargetVel[negative] * speedMultiplier
				if current < target then
					if current > 0 then
						change = -mobility.maxDecel[negative]
					else
						change = -mobility.maxAccel[negative]
					end
				elseif current > target then
					if current > 0 then
						change = -mobility.maxDecel[negative]
					else -- current >= 0
						change = -mobility.maxAccel[negative]
					end
				else -- current - target = 0
					change = 0
				end
			elseif commands[positive] and not commands[negative] then
				target = mobility.maxTargetVel[positive] * speedMultiplier
				if current > target then
					if current < 0 then
						change = mobility.maxDecel[positive]
					else
						change = mobility.maxAccel[positive]
					end
				elseif current < target then
					if current < 0 then
						change = mobility.maxDecel[positive]
					else
						change = mobility.maxAccel[positive]
					end
				else
					change = 0
				end
			else
				target = 0
				if current > target then
					change = -mobility.maxDecel[negative]
				elseif current < target then
					change = mobility.maxDecel[positive]
				else
					change = 0
				end
			end
			return target, change * speedMultiplier
		end
		
		-- Abstraction for using target and change velocities
		local function useVelocities(current, target, change)
			if change > 0 then
				return math.min(target, current + change * dt)
			elseif change < 0 then
				return math.max(target, current + change * dt)
			end
			
			return current
		end
		
		local presence = entity:get(components.presence)
		
		-- Deal with theta
		velocity.theta = useVelocities(velocity.theta, getVelocities("turnLeft", "turnRight", velocity.theta))
		presence.theta = (presence.theta + velocity.theta * dt) % math.tau
		
		do -- Deal with x and y
			local cosine, sine = math.cos(presence.theta), math.sin(presence.theta)
			
			-- Get velocity rotated clockwise
			local relativeVelocityX = velocity.x * cosine + velocity.y * sine
			local relativeVelocityY = velocity.y * cosine - velocity.x * sine
			
			-- Get target and change
			local relativeTargetVelocityX, relatveVelocityChangeX = getVelocities("strafeLeft", "strafeRight", relativeVelocityX)
			local relativeTargetVelocityY, relatveVelocityChangeY = getVelocities("advance", "backpedal", relativeVelocityY)
			
			-- Abstraction to clamp them to an ellipse-like shape (TODO: explain)
			local function clamp(x, y)
				if x ~= 0 and y ~= 0 then
					local currentMag = math.distance(x, y)
					local xSize, ySize = math.abs(x), math.abs(y)
					local maxMag = math.min(xSize, ySize)
					x, y = x / currentMag * maxMag, y / currentMag * maxMag
					x = x * math.max(xSize / ySize, 1)
					y = y * math.max(ySize / xSize, 1)
				end
				return x, y
			end
			
			-- Get clamped velocities
			relativeTargetVelocityX, relativeTargetVelocityY = clamp(relativeTargetVelocityX, relativeTargetVelocityY)
			relatveVelocityChangeX, relatveVelocityChangeY = clamp(relatveVelocityChangeX, relatveVelocityChangeY)
			
			-- Use the velocities
			relativeVelocityX = useVelocities(relativeVelocityX, relativeTargetVelocityX, relatveVelocityChangeX)
			relativeVelocityY = useVelocities(relativeVelocityY, relativeTargetVelocityY, relatveVelocityChangeY)
			
			-- Rotate it back anticlockwise
			velocity.x = relativeVelocityX * cosine - relativeVelocityY * sine
			velocity.y = relativeVelocityY * cosine + relativeVelocityX * sine
			
			-- Add velocity to position
			presence.x, presence.y = presence.x + velocity.x * dt, presence.y + velocity.y * dt
		end
	end
end

function movement:correct()
	
end

return movement
