local constants = require("constants")

local assets = {
	shaders = {
		depth = {load = function(self)
			self.value = love.graphics.newShader("assets/shaders/depth.glsl")
			self.value:send("depth", constants.graphics.channelSize)
		end},
		erode = {load = function(self)
			self.value = love.graphics.newShader("assets/shaders/erode.glsl")
			self.value:send("erodeResolution", constants.graphics.erodeResolution)
			self.value:send("erodeDistance", constants.graphics.erodeDistance)
		end}
	},
	images = {
		ui = {
			font = {-- TODO: make function to process readable text into font-cooperative text
				-- See constants.graphics.fontSpecials
				load = function(self) self.value = love.graphics.newImageFont("assets/images/ui/font.png", constants.graphics.fontString) end
			},
			cursor = {load = function(self) self.value = love.graphics.newImage("assets/images/ui/cursor.png") end}
		}
	} 
}

local function traverse(start)
	for _, v in pairs(start) do
		if v.load then
			v:load()
		else
			traverse(v)
		end
	end
end

return setmetatable(assets, {
	__call = function(assets, action)
		if action == "load" then
			traverse(assets)
		else
			error("Assets is to be called with \"load\"")
		end
	end
})
