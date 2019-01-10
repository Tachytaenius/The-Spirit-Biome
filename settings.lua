local constants = require("constants")
local json = require("lib.json")

local template = {
	buttons = function(try)
		if type(try) == "table" then
			local result = {}
			for k, v in pairs(try) do
				if constants.commands[k] then
					if pcall(love.keyboard.isScancodeDown, v) or pcall(love.mouse.isDown, v) then
						result[k] = v
					else
						print("\"" .. v .. "\" is not a valid input to bind to a command.")
					end
				else
					print("\"" .. k .. "\" is not a valid command to bind inputs to.")
				end
			end
			return result
		else
			return {
				advance = "w",
				strafeLeft = "a",
				backpedal = "s",
				strafeRight = "d",
				turnLeft = ",",
				turnRight = ".",
				
				pause = "escape",
				
				toggleMouseGrab = "f1",
				takeScreenshot = "f2",
				toggleInfo = "f3",
				
				previousDisplay = "f7",
				nextDisplay = "f8",
				scaleDown = "f9",
				scaleUp = "f10",
				toggleFullscreen = "f11",
				
				uiPrimary = 1,
				uiSecondary = 2
			}
		end
	end,
	mouse = {
		divideByScale = function(try) if type(try) == "boolean" then return try else return true end end,
		xSensitivity = function(try) return type(try) == "number" and try or 1 end,
		ySensitivity = function(try) return type(try) == "number" and try or 1 end,
		cursorColour = {
			red = function(try) return type(try) == "number" and try >= 0 and try <= 1 and try or 1 end,
			green = function(try) return type(try) == "number" and try >= 0 and try <= 1 and try or 1 end,
			blue = function(try) return type(try) == "number" and try >= 0 and try <= 1 and try or 1 end,
			alpha = function(try) return type(try) == "number" and try >= 0 and try <= 1 and try or 1 end
		}
	},
	graphics = {
		fullscreen = function(try) return type(try) == "boolean" and try end,
		showPerformance = function(try) return type(try) == "boolean" and try end,
		scale = function(try) return type(try) == "number" and math.isInteger(try) and try >= 1 and try or 1 end,
		display = function(try) return type(try) == "number" and math.isInteger(try) and try >= 1 and try or 1 end
	},
	manualGarbageCollection = {
		enable = function(try) if type(try) == "boolean" then return try else return true end end,
		maxSteps = function(try) return type(try) == "number" and try or 1000 end,
		timeLimit = function(try) return type(try) == "number" and try or 1/600 end,
		safetyMargin = function(try) return type(try) == "number" and try or 64 end -- In mibibytes
	}
}

return setmetatable({}, {
	__call = function(settings, action)
		if action == "save" then
			local success, message = love.filesystem.write("settings.json", json.encode(settings))
			if not success then print(message) end
			return settings
			
		elseif action == "load" then
			local info = love.filesystem.getInfo("settings.json")
			local decoded
			
			if info and info.type ~= "file" then
				print("There is already a non-file item called settings.json. Rename it or move it to use custom settings")
			elseif info then
				-- TODO catch exepctions anstaunsfgusnguf
				decoded = json.decode(love.filesystem.read("settings.json"))
			end
			
			local function traverse(currentTemplate, currentDecoded, currentResult)
				for k, v in pairs(currentTemplate) do
					if type(v) == "table" then
						currentResult[k] = currentResult[k] or {}
						traverse(v, currentDecoded and currentDecoded[k] or nil, currentResult[k])
					elseif type(v) == "function" then
						currentResult[k] = v(currentDecoded and currentDecoded[k])
					else
						error("You can only have tables and functions in the settings template")
					end
				end
			end
			traverse(template, decoded, settings)
			
			if not info then
				print("Couldn't find settings.json, creating")
				settings("save")
			end
			
			return settings("apply")
			
		elseif action == "apply" then
			if settings.graphics.fullscreen then
				local width, height = love.window.getDesktopDimensions(settings.graphics.display)
				love.window.setMode(width, height, {fullscreen = true, borderless = true, display = settings.graphics.display})
			else
				love.window.setMode(constants.graphics.width * settings.graphics.scale, constants.graphics.height * settings.graphics.scale, {fullscreen = false, borderless = false, display = settings.graphics.display})
			end
			
			return settings
			
		else
			error("Settings is to be called with either \"save\", \"load\" or \"apply\"")
		end
	end
})
