local names = {"player", "ai", "position", "mobility"}
local components = {}
for _, name in ipairs(names) do
	components[name] = require("components." .. name)
end
return components
