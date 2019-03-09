return require("lib.concord.component")(
	function(bag, x, y, theta, owner, shape, immovability, clip)
		bag.x, bag.y, bag.theta = x, y, theta
		bag.previousX, bag.previousY, bag.previousTheta = x, y, theta
		
		-- shape <-> bag <-> entity
		shape.bag = bag
		bag.shape = shape
		bag.owner = owner
		
		bag.immovability = immovability
		bag.clip = clip
	end
)
