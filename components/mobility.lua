return require("lib.concord.component")(
	function(bag, primaryAccel, primaryDecel, primaryMaximum, secondaryAccel, secondaryDecel, secondaryMaximum, turnAccel, turnDecel, turnMaximum)
		bag.primaryAccel, bag.primaryDecel, bag.primaryMaximum, bag.secondaryAccel, bag.secondaryDecel, bag.secondaryMaximum, bag.turnAccel, bag.turnDecel, bag.turnMaximum = primaryAccel, primaryDecel, primaryMaximum, secondaryAccel, secondaryDecel, secondaryMaximum, turnAccel, turnDecel, turnMaximum
		bag.x, bag.y, bag.theta = 0, 0, 0
	end
)
