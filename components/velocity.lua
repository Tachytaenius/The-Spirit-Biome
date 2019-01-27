return require("lib.concord.component")(
	function(bag, x, y, theta)
		bag.x, bag.y, bag.theta = x or 0, y or 0, theta or 0
	end
)
