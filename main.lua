local assets = require("assets")
local constants = require("constants")
local settings = require("settings")

local input = require("input")
local world = require("world")
local suit = require("lib.suit")
local concord = require("lib.concord").init()
local components = require("components")

local contentCanvas, play, ui

function love.load(args)
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	contentCanvas, ui = love.graphics.newCanvas(constants.graphics.width, constants.graphics.height), {
		-- type = nil,
		-- mouseX = nil,
		-- mouseY = nil
	}
	input.frameUpdates = {{}, {}}
	input.fixedUpdates = {{}, {}}
	input.recording = false -- TODO
	input.replaying = false -- TODO
	settings("load")
	assets("load")
	love.graphics.setFont(assets.images.ui.font.value)
	
	if not args[1] or args[1] == "new" then
		local seed = args[2] or love.math.random(2 ^ 53) - 1
		local rng = love.math.newRandomGenerator(seed)
		play = {
			canvas = love.graphics.newCanvas(constants.graphics.width, constants.graphics.height),
			worlds = {world(-50, -50, 50, 50, rng)}
		}
		play.cameraEntity = concord.entity()
		play.cameraEntity:give(components.presence, 0, 0, 0, play.cameraEntity, play.worlds[1].collider:circle(0, 0, 20), 50, true):give(components.player, 1):give(components.velocity):give(
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
				advance = 175,
				backpedal = 150,
				strafeLeft = 155,
				strafeRight = 155,
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
		play.worlds[1]:addEntity(play.cameraEntity)
		local new = concord.entity()
		new:give(components.presence, 0, 0, 0, new, play.worlds[1].collider:circle(0, 0, 20), 100, true):give(components.velocity)
		play.worlds[1]:addEntity(new)
	elseif args[1] == "load" then
		local path = args[2]
		
	else
		knowledged.error("Invalid first argument: " .. args[1])
	end
end

function love.update(dt)
	-- TODO: Particles
	-- TODO: Save recording
	
	if input.checkFrameUpdateCommand("pause") then
		if ui.type then
			ui.type = nil
			ui.mouseX, ui.mouseY = nil, nil
		else
			ui.type = "paused"
			ui.mouseX, ui.mouseY = constants.graphics.width / 2, constants.graphics.height / 2
		end
	end
	
	if input.checkFrameUpdateCommand("toggleMouseGrab") then
		love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
	end
	
	if input.checkFrameUpdateCommand("takeScreenshot") then
		local info = love.filesystem.getInfo("screenshots")
		if info and info.type ~= "directory" then
			print("There is already a non-folder item called screenshots. Rename it or move it to take a screenshot")
			return
		elseif not info then
			print("Couldn't find screenshots folder. Creating")
			love.filesystem.createDirectory("screenshots")
		end
		local current = 0
		for _, filename in pairs(love.filesystem.getDirectoryItems("screenshots")) do
			local name = string.sub(filename, 1, -5) -- remove ".png"
			if name then
				local number = tonumber(name)
				if number and number > current then current = number end
			end
		end
		local data = play.canvas:newImageData()
		data:mapPixel(
			function(x, y, r, g, b, a)
				return math.round(r, constants.graphics.channelSize - 1), math.round(g, constants.graphics.channelSize - 1), math.round(b, constants.graphics.channelSize - 1), 1
			end
		)
		data:encode("png", "screenshots/" .. current + 1 .. ".png")
	end
	
	if input.checkFrameUpdateCommand("previousDisplay") then
		settings.graphics.display = (settings.graphics.display - 1) % love.window.getDisplayCount()
	end
	
	if input.checkFrameUpdateCommand("nextDisplay") then
		settings.graphics.display = (settings.graphics.display + 1) % love.window.getDisplayCount()
	end
	
	if settings.graphics.scale > 1 and input.checkFrameUpdateCommand("scaleDown") then
		settings.graphics.scale = settings.graphics.scale - 1
		settings("apply")
		settings("save")
	end
	
	if input.checkFrameUpdateCommand("scaleUp") then
		settings.graphics.scale = settings.graphics.scale + 1
		settings("apply")
		settings("save")
	end
	
	if input.checkFrameUpdateCommand("toggleFullscreen") then
		settings.graphics.fullscreen = not settings.graphics.fullscreen
		settings("apply")
		settings("save")
	end
	
	if input.checkFrameUpdateCommand("toggleInfo") then
		settings.graphics.showPerformance = not settings.graphics.showPerformance
		settings("save")
	end
	
	if ui.type then
		suit.updateMouse(ui.mouseX, ui.mouseY, input.checkFrameUpdateCommand("uiPrimary") or false) -- nil will make no change, but false will
		if ui.type == "paused" then
			suit.layout:reset(constants.graphics.horizontalMenuOffset, constants.graphics.verticalMenuOffset, constants.graphics.menuPadding)
			if suit.Button("Resume", suit.layout:row(constants.graphics.horizontalMenuSize, constants.graphics.menuRowHeight)).hit then
				ui.type = nil
				ui.mouseX, ui.mouseY = nil, nil
			end
			if suit.Button("Quit", suit.layout:row()).hit then
				love.event.quit()
			end
		end
	else
		suit.exitFrame()
		suit.enterFrame()
	end
	
	input.stepFrameUpdate()
end

function love.fixedUpdate(dt)
	assert(dt == constants.core.tickWorth, "A fixed update represents a fixed amount of time")
	
	local cameraWorld = play.cameraEntity.instances:get(1)
	if not love.graphics.isActive() or not settings.graphics.interpolation then
		if cameraWorld.hasLerpValues then
			cameraWorld:emit("clearLerpValues")
			cameraWorld.hasLerpValues = false
		end
	end
	
	if ui.type ~= "paused" then
		if love.graphics.isActive() and settings.graphics.interpolation then
			cameraWorld:emit("copyLerpValues")
			cameraWorld.hasLerpValues = true
		end
		
		local realmTransfers = {}
		for _, world in ipairs(play.worlds) do
			world:emit("execute", dt)
			world:emit("correct")
			realmTransfers[world] = {
				-- [entity] = destinationWorld
			}
			world:emit("getRealmTransfers", realmTransfers[world])
		end
		for source, transfersFromSource in pairs(realmTransfers) do
			for entity, destination in pairs(transfersFromSource) do
				-- TODO
				-- Please don't forget to do stuff with relativity children
				-- If the camera entity moves change the camera world too
			end
		end
		
		input.stepFixedUpdate()
	end
end

function love.draw(lerp)
	if ui.type ~= "paused" then
		love.graphics.setCanvas(play.canvas)
		love.graphics.clear()
		play.cameraEntity.instances:get(1):emit("draw", lerp, play.cameraEntity)
	end
	love.graphics.setCanvas(contentCanvas)
	love.graphics.clear()
	love.graphics.draw(play.canvas)
	if ui.type then
		love.graphics.setColor(1, 1, 1)
		suit.draw()
		love.graphics.setColor(settings.mouse.cursorColour)
		love.graphics.draw(assets.images.ui.cursor.value, math.floor(ui.mouseX), math.floor(ui.mouseY))
		love.graphics.setColor(1, 1, 1)
	end
	if settings.graphics.showPerformance then
		love.graphics.print("FPS: " .. love.timer.getFPS() .. "\nDrawcalls: " .. love.graphics.getStats().drawcalls)
	end
	love.graphics.setCanvas(nil)
	
	local x, y
	if settings.graphics.fullscreen then
		local width, height = love.window.getDesktopDimensions()
		x = (width - constants.graphics.width * settings.graphics.scale) / 2
		y = (height - constants.graphics.height * settings.graphics.scale) / 2
	end
	
	love.graphics.setShader(assets.shaders.depth.value)
	love.graphics.draw(contentCanvas, x or 0, y or 0, 0, settings.graphics.scale)
	love.graphics.setShader(nil)
end

-- The following function is based on the MIT licensed code here: https://gist.github.com/Positive07/5e80f03cabd069087930d569c148241c
-- Copyright (c) 2019 Arvid Gerstmann, Jake Besworth, Max, Pablo Mayobre, LÖVE Developers, Henry Fleminger Thomson

function love.run()
	love.load(love.arg.parseGameArguments(arg))
	local lag = 0
	love.timer.step()
	
	return function()
		do -- Events
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
		
		do -- Update
			local delta = love.timer.step()
			local start = love.timer.getTime()
			lag = math.min(lag + delta, constants.core.tickWorth * constants.core.maxTickSkip)
			local frames = math.floor(lag / constants.core.tickWorth)
			lag = lag % constants.core.tickWorth
			love.update(delta)
			for _=1, frames do
				love.fixedUpdate(constants.core.tickWorth)
			end
		end
		
		if love.graphics.isActive() then -- Rendering
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.draw(lag / constants.core.tickWorth)
			love.graphics.present()
		end
		
		if not settings.manualGarbageCollection.enable then -- Garbage collection
			local start = love.timer.getTime()
			for _=1, settings.manualGarbageCollection.maxSteps do
				if love.timer.getTime() - start > settings.manualGarbageCollection.timeLimit then break end
				collectgarbage("step", 1)
			end
			
			if collectgarbage("count") / 1024 > settings.manualGarbageCollection.safetyMargin then
				collectgarbage("collect")
			end
			
			collectgarbage("stop")
		end
		
		love.timer.sleep(0.001)
	end
end

function love.quit()
	
end

function love.mousemoved(x, y, dx, dy)
	if love.window.hasMouseFocus() and love.mouse.getRelativeMode() then
		if ui.type then
			local div = settings.mouse.divideByScale and settings.graphics.scale or 1
			ui.mouseX = math.clamp(0, ui.mouseX + (dx * settings.mouse.xSensitivity) / div, constants.graphics.width)
			ui.mouseY = math.clamp(0, ui.mouseY + (dy * settings.mouse.ySensitivity) / div, constants.graphics.height)
		else
			
		end
	end
end
