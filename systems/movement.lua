local input = require("input")
local constants = require("constants")
local components = require("components")
local movement = require("lib.concord.system")(
	{"mobs", components.actor, components.position, components.velocity, components.mobility}
)

local movementCommandsToCheck = {
	advance = true,
	strafeLeft = true,
	backpedal = true,
	strafeRight = true,
	turnLeft = true,
	turnRight = true
}

local terrain = {{}, {}, {}}
for _, terrain in pairs(terrain) do
	for _=1, 7998 do
		table.insert(terrain, (math.ndRandom() - 0.5) * 1500)
	end
end

function movement:draw()
	for i = 1, self.mobs.size do
		local sooch = self.mobs:get(i):get(components.position)
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
		local xdispl, ydispl = self.mobs:get(i):get(components.mobility).x * 4, self.mobs:get(i):get(components.mobility).y * 4
		love.graphics.line(sooch.x, sooch.y, sooch.x + xdispl, sooch.y + ydispl)
		love.graphics.origin()
	end
end

function movement:fixedUpdate(dt)
	for i = 1, self.mobs.size do
		local entity = self.mobs:get(i)
		local commands
		
		do -- Get commands
			local ai = entity:get(components.ai)
			local player = entity:get(components.player)
			
			if ai then
				commands = ai.actions
			else
				commands = {}
				for command in pairs(movementCommandsToCheck) do
					commands[command] = input.checkFixedUpdateCommand(command)
				end
			end
		end
		
		do -- Execute commands
			local position = entity:get(components.position)
			local mobility = entity:get(components.mobility)
			
			local targetX, targetY = 0, 0
			
			-- Back and forth
			if commands.advance and not commands.backpedal then
				targetY = -mobility.primaryMaximum
			elseif commands.backpedal and not commands.advance then
				targetY = mobility.primaryMaximum
			end
			
			-- Strafe
			if commands.strafeLeft and not commands.strafeRight then
				targetX = -mobility.secondaryMaximum
			elseif commands.strafeRight and not commands.strafeLeft then
				targetX = mobility.secondaryMaximum
			end
			
			local xSize, ySize = targetY < 0 and mobility.secondaryMaximum or mobility.secondaryMaximum, targetX < 0 and mobility.primaryMaximum or mobility.primaryMaximum
			local currentMagnitude = math.distance(targetX, targetY)
			if currentMagnitude > 0 then
				local maximumMagnitude = math.min(xSize, ySize)
				targetX, targetY = targetX / currentMagnitude * maximumMagnitude, targetY / currentMagnitude * maximumMagnitude
			end
			if xSize > ySize then
				targetX = targetX * xSize / ySize
			else
				targetY = targetY * ySize / xSize
			end
			
			local targetTheta = 0
			if commands.turnLeft and not commands.turnRight then
				targetTheta = -mobility.turnMaximum
			elseif commands.turnRight then
				targetTheta = mobility.turnMaximum
			end
			if targetTheta > mobility.theta then
				mobility.theta = math.min(mobility.theta + mobility.turnAccel * dt, targetTheta)
			else
				mobility.theta = math.max(mobility.theta - mobility.turnAccel * dt, targetTheta)
			end
			position.theta = position.theta + mobility.theta * dt
			
			local cosine, sine = math.cos(-position.theta), math.sin(-position.theta)
			local currentX, currentY =
				mobility.x * cosine - mobility.y * sine,
				mobility.y * cosine + mobility.x * sine
			
			-- FIXME: Deceleration through 0 will simulate deceleration above zero
			
			local moveX, moveY
			local changeX = math.sgn(targetX) == math.sgn(currentX) and mobility.secondaryAccel or mobility.secondaryDecel
			local changeY = math.sgn(targetY) == math.sgn(currentY) and mobility.primaryAccel or mobility.primaryDecel
			
			if targetX > currentX then
				moveX = math.min(currentX + changeX * dt, targetX)
			else
				moveX = math.max(currentX - changeX * dt, targetX)
			end
			
			if targetY > currentY then
				moveY = math.min(currentY + changeY * dt, targetY)
			else
				moveY = math.max(currentY - changeY * dt, targetY)
			end
			
			local cosine, sine = math.cos(position.theta), math.sin(position.theta)
			moveX, moveY =
				moveX * cosine - moveY * sine,
				moveY * cosine + moveX * sine
			mobility.x, mobility.y = moveX, moveY
			
			position.x, position.y = position.x + mobility.x, position.y + mobility.y
		end
	end
end

return movement
