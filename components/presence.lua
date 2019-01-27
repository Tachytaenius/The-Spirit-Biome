return require("lib.concord.component")(
	function(bag, x, y, theta, owner, shape)
		-- shape <-> bag <-> entity
		bag.x, bag.y, bag.theta = x, y, theta
		shape.bag = bag
		bag.shape = shape
		bag.owner = owner
	end
)
