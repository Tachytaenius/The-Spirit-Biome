local constants = {}

constants.core = {}
constants.core.title = "The Spirit Biome"
constants.core.identity = "biome"
constants.core.tickWorth = 1 / 30 -- seconds
constants.core.maxTickSkip = 8

constants.gameplay = {}
constants.gameplay.metre = 12
constants.gameplay.cellSize = constants.gameplay.metre * 2
constants.gameplay.zeroSnap = 0.05

constants.graphics = {}
constants.graphics.width = 480
constants.graphics.height = 270
constants.graphics.channelSize = 256
constants.graphics.erodeResolution = 2
constants.graphics.erodeDistance = 1
constants.graphics.horizontalMenuOffset = constants.graphics.width / math.phi / 2
constants.graphics.verticalMenuOffset = constants.graphics.height / math.phi / 2
constants.graphics.horizontalMenuSize = constants.graphics.width - constants.graphics.horizontalMenuOffset * 2
constants.graphics.verticalMenuSize = constants.graphics.height - constants.graphics.verticalMenuOffset * 2
constants.graphics.menuPadding = 4
constants.graphics.menuRowHeight = 20
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

constants.fixedUpdateCommands = { 
	advance = "whileDown",
	strafeLeft = "whileDown",
	backpedal = "whileDown",
	strafeRight = "whileDown",
	turnLeft = "whileDown",
	turnRight = "whileDown",
	run = "whileDown",
	sneak = "whileDown"
}

constants.frameUpdateCommands = {
	pause = "onRelease",
	
	toggleMouseGrab = "onRelease",
	takeScreenshot = "onRelease",
	toggleInfo = "onRelease",
	previousDisplay = "onRelease",
	nextDisplay = "onRelease",
	scaleUp = "onRelease",
	scaleDown = "onRelease",
	toggleFullscreen = "onRelease",
	
	uiPrimary = "whileDown",
	uiSecondary = "whileDown"
}

return constants
