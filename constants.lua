local constants = {}

constants.core = {}
constants.core.title = "The Spirit Biome"
constants.core.identity = "biome"
constants.core.tickWorth = 1 / 24 -- seconds
constants.core.maxTickSkip = 8

constants.graphics = {}
constants.graphics.width = 480
constants.graphics.height = 270
constants.graphics.channelSize = 16
constants.graphics.erodeResolution = 2
constants.graphics.erodeDistance = 1
constants.graphics.horizontalMenuOffset = constants.graphics.width / math.phi / 2
constants.graphics.verticalMenuOffset = constants.graphics.height / math.phi / 2
constants.graphics.horizontalMenuSize = constants.graphics.width - constants.graphics.horizontalMenuOffset * 2
constants.graphics.verticalMenuSize = constants.graphics.height - constants.graphics.verticalMenuOffset * 2
constants.graphics.menuRowHeight = 22
constants.graphics.fontString = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.!?$,#@~:;-{}|&()<>'[]^£%/\\*0123456789"
constants.graphics.fontSpecials = {
	{from = "\"[", to = "<"}, -- open quote
	{from = "\"]", to = ">"}, -- close quote
	{from = "?!", to = "$"}, -- interrobang
	{from = "---", to = "}"}, -- em dash
	{from = "--", to = "{"}, -- en dash
	{from = "[deg]", to = "^"}, -- degrees symbol
	{from = "[cur]", to = "£"}, -- currency symbol
	{from = "!,", to = "#"}, -- exclamation comma
	{from = "?,", to = "@"}, -- question comma
	{from = "$,", to = "~"} -- interrobang comma
}

-- TODO: regular expression for niceness
-- whileDown, onRelease, onPress
-- recorded, unrecorded

local whileDown_recorded = {deltaPolicy = "whileDown", recorded = true}
local whileDown_unrecorded = {deltaPolicy = "whileDown", recorded = false}
local onRelease_unrecorded = {deltaPolicy = "onRelease", recorded = false}

constants.commands = { 
	advance = whileDown_recorded,
	strafeLeft = whileDown_recorded,
	backpedal = whileDown_recorded,
	strafeRight = whileDown_recorded,
	turnLeft = whileDown_recorded,
	turnRight = whileDown_recorded,
	
	pause = onRelease_unrecorded,
	
	toggleMouseGrab = onRelease_unrecorded,
	takeScreenshot = onRelease_unrecorded,
	toggleInfo = onRelease_unrecorded,
	previousDisplay = onRelease_unrecorded,
	nextDisplay = onRelease_unrecorded,
	scaleUp = onRelease_unrecorded,
	scaleDown = onRelease_unrecorded,
	toggleFullscreen = onRelease_unrecorded,
	
	uiPrimary = whileDown_unrecorded,
	uiSecondary = whileDown_unrecorded
}

return constants
