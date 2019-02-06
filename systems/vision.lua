local constants = require("constants")
local components = require("components")
local vision = require("lib.concord.system")(
	{"seers", components.ai, components.sight},
	{""},
	{"presences", components.presence}
)



return vision
