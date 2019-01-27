local names = {"player", "ai", "presence", "mobility", "velocity"}
local components = {}
for _, name in ipairs(names) do
	components[name] = require("components." .. name)
end
return components
