local settings = require("settings")
local constants = require("constants")

local input = {}

function input.step()
	assert(not input.replaying, "input.step is called every fixed update when you are making new footage or playing unrecorded")
	
	if not input.recording then
		table.remove(input.ticks, 1)
	end
	table.insert(input.ticks, {})
end

function input.flushRecording()
	asset(input.recording, "input.flushRecording is called every frame update when recording")
	
	while #input.ticks > 2 do
		-- accumulate the tick's inputs (TODO, dont know format)
		-- delete unrecordeds too
		table.remove(input.ticks, 1)
	end
	-- write it to demo file
end

function input.checkCommand(command)
	assert(constants.commands[command], "A command has to be registered if you want to check for it")
	
	local assignee = settings.buttons[command]
	local downThisTick
	if (type(assignee) == "string" and love.keyboard.isScancodeDown(assignee)) or (type(assignee) == "number" and love.mouse.isGrabbed() and love.mouse.isDown(assignee)) then
		input.ticks[#input.ticks][command], downThisTick = true, true
	end
	local commandInfo = constants.commands[command]
	if commandInfo.deltaPolicy == "onPress" then
		return downThisTick and not input.ticks[#input.ticks - 1][command]
	elseif commandInfo.deltaPolicy == "onRelease" then
		return not downThisTick and input.ticks[#input.ticks - 1][command]
	elseif commandInfo.deltaPolicy == "whileDown" then
		return downThisTick
	else
		error("Command delta policies must be either \"onPress\", \"onRelease\" or \"whileDown\"")
	end
end

return input
