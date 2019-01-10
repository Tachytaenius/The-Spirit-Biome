local assets = require("assets")
local constants = require("constants")
local settings = require("settings")

local input = require("input")
local suit = require("lib.suit")
local concord = require("lib.concord").init()

local contentCanvas, play, ui

function love.load(args)
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	contentCanvas, ui = love.graphics.newCanvas(constants.graphics.width, constants.graphics.height), {
		-- type = nil,
		-- mouseX = nil,
		-- mouseY = nil
	}
	input.ticks = {{}, {}}
	input.recording = false -- TODO
	input.replaying = false -- TODO
	settings("load")
	assets("load")
	love.graphics.setFont(assets.images.ui.font.value)
	
	if not args[1] or args[1] == "new" then
		local seed = args[2] or love.math.random(2 ^ 53) - 1
		play = {
			canvas = love.graphics.newCanvas(constants.graphics.width, constants.graphics.height),
			worlds = {}
			
		}
	elseif args[1] == "load" then
		local path = args[2]
		
	else
		knowledged.error("Invalid first argument: " .. args[1])
	end
end

function love.update(dt)
	-- TODO: Particles
	-- TODO: Save recording
	
	if ui.type then
		suit.updateMouse(ui.mouseX, ui.mouseY, input.checkCommand("uiPrimary") or false) -- nil will make no change, but false will
		if ui.type == "paused" then
			suit.layout:reset(constants.graphics.horizontalMenuOffset, constants.graphics.verticalMenuOffset)
			if suit.Button("Quit", suit.layout:row(constants.graphics.horizontalMenuSize, constants.graphics.verticalMenuSize)).hit then
				love.event.quit()
			end
		end
	else
		suit.exitFrame()
		suit.enterFrame()
	end
end

function love.fixedUpdate(dt)
	assert(dt == constants.core.tickWorth, "A fixed update represents a fixed amount of time")
	
	input.step()
	
	if input.checkCommand("pause") then
		if ui.type then
			ui.type = nil
			ui.mouseX, ui.mouseY = nil, nil
		else
			ui.type = "paused"
			ui.mouseX, ui.mouseY = constants.graphics.width / 2, constants.graphics.height / 2
		end
	end
	
	if input.checkCommand("toggleMouseGrab") then
		love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
	end
	
	if input.checkCommand("takeScreenshot") then
		local info = love.filesystem.getInfo("screenshots")
		if info and info.type ~= "directory" then
			print("There is already a non-folder item called screenshots. Rename it or move it to take a screenshot.")
			return
		elseif not info then
			print("Couldn't find screenshots folder. Creating.")
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
		local data = contentCanvas:newImageData()
		data:mapPixel(
			function(x, y, r, g, b, a)
				return math.round(r, constants.graphics.channelSize - 1), math.round(g, constants.graphics.channelSize - 1), math.round(b, constants.graphics.channelSize - 1), 1
			end
		)
		data:encode("png", "screenshots/" .. current + 1 .. ".png")
	end
	
	if input.checkCommand("previousDisplay") then
		settings.graphics.display = (settings.graphics.display - 1) % love.window.getDisplayCount()
	end
	
	if input.checkCommand("nextDisplay") then
		settings.graphics.display = (settings.graphics.display + 1) % love.window.getDisplayCount()
	end
	
	if settings.graphics.scale > 1 and input.checkCommand("scaleDown") then
		settings.graphics.scale = settings.graphics.scale - 1
		settings("apply")
		settings("save")
	end
	
	if input.checkCommand("scaleUp") then
		settings.graphics.scale = settings.graphics.scale + 1
		settings("apply")
		settings("save")
	end
	
	if input.checkCommand("toggleFullscreen") then
		settings.graphics.fullscreen = not settings.graphics.fullscreen
		settings("apply")
		settings("save")
	end
	
	if input.checkCommand("toggleInfo") then
		settings.graphics.showPerformance = not settings.graphics.showPerformance
		settings("save")
	end
end

function love.draw(interpolation)
	if ui.type ~= "paused" then
		love.graphics.setCanvas(play.canvas)
		-- draw play
	end
	love.graphics.setCanvas(contentCanvas)
	love.graphics.clear(0, 0, 0)
	love.graphics.draw(play.canvas)
	if ui.type then
		suit.draw()
		love.graphics.setColor(
			settings.mouse.cursorColour.red,
			settings.mouse.cursorColour.green,
			settings.mouse.cursorColour.blue,
			settings.mouse.cursorColour.alpha
		)
		love.graphics.draw(assets.images.ui.cursor.value, math.floor(ui.mouseX), math.floor(ui.mouseY))
		love.graphics.setColor(1, 1, 1)
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
			love.draw(lag)
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
