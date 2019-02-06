return require("lib.concord.component")(
	function(bag, x, y, theta, owner, shape, immovability, clip)
		-- shape <-> bag <-> entity
		bag.x, bag.y, bag.theta = x, y, theta
		
		-- remove later TODO
		bag.alpha = 1
		
		
		shape.bag = bag
		bag.shape = shape
		bag.owner = owner
		
		bag.immovability = immovability
		bag.clip = clip
	end
)
