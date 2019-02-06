local input = require("input")
local constants = require("constants")
local settings = require("settings")
local components = require("components")
local movement = require("lib.concord.system")(
	{"mobs", components.presence, components.velocity, components.mobility},
	{"presences", components.presence}
)

local terrain = {}
for i = 1, 12 do
	terrain[i] = {}
	for _ = 1, 2000 do
		local x, y = math.polarToCartesian(math.ndRandom() * 5000, math.ndRandom() * math.tau)
		table.insert(terrain[i], x)
		table.insert(terrain[i], y)
		-- table.insert(terrain, (math.ndRandom() * 2 - 1) * 2000)
		-- table.insert(terrain, (math.ndRandom() * 2 - 1) * 2000)
	end
end

local function hsvToRgb(h, s, v, a)
	local r, g, b
	
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	
	i = i % 6
	
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	
	return r, g, b, a
end

-- remove m TODO e l8r
local tunnelStartX, tunnelStartY = 50, 80
local tunnelEndX, tunnelEndY = 200, 300
local tunnelRange = 100

function movement:draw(lerp, entity)
	if not entity then return end
	assert(self:getInstance().entities:has(entity), "Emitted draw into the wrong instance; it should contain the camera entity")
	
	local function angle(previous, current)
		return previous + math.angleDifference(current, previous) * lerp
	end
	
	local function ordinate(previous, current)
		return current * lerp + previous * (1 - lerp)
	end
	
	local presence = entity:get(components.presence)
	
	love.graphics.clear(1 - presence.alpha, 1 - presence.alpha, 1 - presence.alpha)
	
	local presenceX, presenceY, presenceTheta = presence.x, presence.y, presence.theta
	if settings.graphics.interpolation and self:getInstance().hasLerpValues then
		presenceX = ordinate(presence.previousX, presenceX)
		presenceY = ordinate(presence.previousY, presenceY)
		presenceTheta = angle(presence.previousTheta, presenceTheta)
	end
	
	love.graphics.translate(constants.graphics.width / 2, constants.graphics.height - 80)
	love.graphics.rotate(-presenceTheta)
	love.graphics.setPointSize(1)
	
	for i = #terrain, 1, -1 do
		local points = terrain[i]
		
		love.graphics.push()
		local r, g, b = hsvToRgb((2 * i / #terrain) % 1, 1, 1)
		love.graphics.setColor(r, g, b, 1 - (i - 1) / #terrain)
		love.graphics.scale(1 - (i - 1) / #terrain)
		love.graphics.translate(-presenceX, -presenceY)
		love.graphics.points(unpack(points))
		love.graphics.pop()
	end
	
	love.graphics.translate(-presenceX, -presenceY)
	
	love.graphics.line(tunnelStartX, tunnelStartY, tunnelEndX, tunnelEndY)
	love.graphics.setPointSize(8)
	love.graphics.points(tunnelEndX, tunnelEndY)
	
	for shape in pairs(self:getInstance().collider:hash():shapes()) do
		shape:draw("fill")
	end
	
	love.graphics.setPointSize(3)
	love.graphics.setColor(1, 1, 1)
	love.graphics.points(presenceX, presenceY)
	love.graphics.origin()
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

function movement:copyLerpValues()
	for i = 1, self.presences.size do
		local presence = self.presences:get(i):get(components.presence)
		presence.previousX, presence.previousY, presence.previousTheta = presence.x, presence.y, presence.theta
	end
end

function movement:clearLerpValues()
	for i = 1, self.presences.size do
		local presence = self.presences:get(i):get(components.presence)
		presence.previousX, presence.previousY, presence.previousTheta = nil, nil, nil
	end
end

function movement:execute(dt)
	self.moved = {}
	
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
			local newVelocityX = relativeVelocityX * cosine - relativeVelocityY * sine
			local newVelocityY = relativeVelocityY * cosine + relativeVelocityX * sine
			if newVelocityX ~= velocity.x or newVelocityY ~= velocity.y then
				table.insert(self.moved, entity)
			end
			
			velocity.x = newVelocityX
			velocity.y = newVelocityY
			
			do -- thing, remove later TODO?
				local tunnelAngle = math.angle(tunnelEndX - tunnelStartX, tunnelEndY - tunnelStartY)
				local movementAngle = math.angle(velocity.x, velocity.y)
				local direction = math.abs(math.angleDifference(tunnelAngle, movementAngle)) / (math.tau / 2) * 2 - 1
				local distanceAlpha = math.max(tunnelRange - math.segmentPointDistance(tunnelStartX, tunnelStartY, tunnelEndX, tunnelEndY, presence.x, presence.y), 0) / tunnelRange
				
				presence.alpha = math.clamp(0, presence.alpha + direction * distanceAlpha * math.distance(velocity.x, velocity.y) * dt / math.distance(tunnelStartX - tunnelEndX, tunnelStartY - tunnelEndY), 1)
			end
			
			-- Add velocity to position
			presence.x, presence.y = presence.x + velocity.x * dt, presence.y + velocity.y * dt
		end
	end
end

function movement:correct()
	local randomShifts, randomShiftMagnitudes = {}, {}
	local xShifts, yShifts = {}, {}
	
	for i = 1, self.presences.size do
		local entity = self.presences:get(i)
		local presence = entity:get(components.presence)
		if presence.clip then
			for other, vector in pairs(self:getInstance().collider:collisions(presence.shape)) do
				-- Make sure the other shape also clips, and also make sure it can move
				if other.bag.clip and other.bag.owner:get(components.velocity) then
					local pusherImmovability, pusheeImmovability = presence.immovability, other.bag.immovability
					local pusherFactor -- How much of the vector moves the pusher
					if pusheeImmovability == pusherImmovability then
						pusherFactor = 0.5
					elseif pusheeImmovability == math.huge and pusherImmovability ~= math.huge then
						pusherFactor = 1
					elseif pusheeImmovability ~= math.huge and pusherImmovability == math.huge then
						pusherFactor = 0
					else
						pusherFactor = pusheeImmovability / (pusherImmovability + pusheeImmovability)
					end
					local pusheeFactor = 1 - pusherFactor
					local vx, vy = vector.x, vector.y
					if presence.x == other.bag.x and presence.y == other.bag.y then
						-- If we're in the same place then we push in a pseudorandom direction (deterministic, of course)
						table.insert(randomShifts, other.bag)
						randomShiftMagnitudes[other.bag] = pusheeFactor * math.distance(vx, vy)
					else
						xShifts[other.bag] = xShifts[other.bag] and xShifts[other.bag] + pusheeFactor * -vx or pusheeFactor * -vx
						yShifts[other.bag] = yShifts[other.bag] and yShifts[other.bag] + pusheeFactor * -vy or pusheeFactor * -vy
						xShifts[presence] = xShifts[presence] and xShifts[presence] + pusherFactor * vx or pusherFactor * vx
						yShifts[presence] = yShifts[presence] and yShifts[presence] + pusherFactor * vy or pusherFactor * vy
					end
				end
			end
		end
	end
	
	table.sort(randomShifts,
		function(i, j)
			-- Determinism is maintained because Concord's pool order is deterministic
			return self.presences.pointers[i.owner] < self.presences.pointers[j.owner]
		end
	)
	
	local rng = self:getInstance().rng
	
	for _, pushedPresence in ipairs(randomShifts) do
		local vx, vy = math.polarToCartesian(
			randomShiftMagnitudes[pushedPresence],
			rng:random() * math.tau
		)
		xShifts[pushedPresence] = xShifts[pushedPresence] and xShifts[pushedPresence] + vx or vx
		yShifts[pushedPresence] = yShifts[pushedPresence] and yShifts[pushedPresence] + vy or vy
	end
	
	for shiftee, xAmount in pairs(xShifts) do
		shiftee.x = shiftee.x + xAmount
		shiftee.y = shiftee.y + yShifts[shiftee] -- If you shift on the x only you'll still have a 0 in the yShifts
	end
	
	for i = 1, self.presences.size do
		local entity = self.presences:get(i)
		local presence = entity:get(components.presence)
		
		presence.shape:moveTo(presence.x, presence.y)
	end
end

return movement
