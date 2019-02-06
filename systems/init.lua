local names = {"movement", "vision"}
local systems = {}
for _, name in ipairs(names) do
	systems[name] = require("systems." .. name)
end
return systems
