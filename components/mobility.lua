return require("lib.concord.component")(
	function(bag, maxTargetVel, maxAccel, maxDecel)
		bag.maxTargetVel, bag.maxAccel, bag.maxDecel = maxTargetVel, maxAccel, maxDecel
	end
)
