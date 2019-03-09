-- Daisychain is a library for parent-child relationships in HC
-- It's by Tachytaenius

--[[
	MIT License

	Copyright (c) 2019 Henry Fleminger Thomson

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local daisychain = {}

local instanceMethods = {}

function instanceMethods:setParent(child, newParent)
	self.top[child] = newParent == nil or nil
	local oldParent = self.parents[child]
	if oldParent == newParent then return end
	if oldParent then
		local oldFamily = self.families[oldParent]
		oldFamily[child] = nil
		
		-- TODO: Just tell garbage collector that the family may be collected if it is empty instead of deleting it as soon as it becomes empty?
		local oldFamilyPopulated
		for _ in pairs(oldFamily) do
			oldFamilyPopulated = true
			break
		end
		if not oldFamilyPopulated then self.families[oldParent] = nil end
	end
	if newParent then
		local newFamily = self.families[newParent]
		if not newFamily then
			newFamily = {}
			self.families[newParent] = newFamily
		end
		newFamily[child] = true
	end
	self.parents[child] = newParent
	if newParent then
		local parentBuffer = {}
		local current = newParent
		while current do
			assert(not parentBuffer[current], "Loop detected!")
			parentBuffer[current] = true
			current = self.parents[current]
		end
	end
end

local cos, sin, tau = math.cos, math.sin, math.tau or math.pi * 2

local function setPolygonTransform(polygon, base, x, y, cosine, sine)
	polygon.centroid.x, polygon.centroid.y = x + base.centroid.x * cosine + base.centroid.y * sine, y + base.centroid.y * cosine - base.centroid.x * sine
	local vertices = polygon.vertices
	for i, v in ipairs(base) do
		-- Could be done with daisychain.transformCoordinates, but... indexing (and if not, call overhead)
		vertices[i].x, vertices[i].y = x + v.x * cosine + v.y * sine, y + v.y * cosine - v.x * sine
	end
end

function instanceMethods:update(object, x, y, r)
	if object == nil then
		-- Do the block below for all the top-level shapes
		for child in pairs(self.top) do
			self:update(child, 0, 0, 0)
		end 
	else
		local attributes = self.attributes[object]
		-- Transform origin
		x, y, r = daisychain.transformTransform(x, y, r, attributes.relx, attributes.rely, attributes.relr)
		
		-- If its previous absolute transform is different to the current one...
		if not (x == attributes.pabsx and y == attributes.pabsy and r == attributes.pabsr) or not attributes.hasPreviousAbsolutes then
			attributes.pabsx, attributes.pabsy, attributes.pabsr, attributes.hasPreviousAbsolutes = x, y, r, true
			local x1,y1,x2,y2 = object:bbox()
			if attributes.type == "circle" then
				object._center.x, object._center.y = x, y
			elseif attributes.type == "point" then
				object._pos.x, object._pos.y = x, y
			elseif attributes.type == "concavePolygon" then
				setPolygonTransform(object._polygon, attributes.base, x, y, cos(r), sin(r))
				for i, part in ipairs(object._shapes) do
					setPolygonTransform(part._polygon, attributes.partBases[i], x, y, cos(r), sin(r))
				end
			elseif attributes.type == "convexPolygon" then
				setPolygonTransform(object._polygon, attributes.base, x, y, cos(r), sin(r))
			end
			attributes.hash:update(object, x1,y1,x2,y2, object:bbox())
		end
		
		-- Do this for the children as well, with this shape's transformation as the origin
		if self.families[object] then
			for child in pairs(self.families[object]) do
				self:update(child, x, y, r)
			end
		end
	end
end

-- You can also get an object's absolute position from pabsx, pabsy and pabsr (standing for previous absolute x, y and rotation) in its attributes as long as you updated at the time you want to get the absolute position from
-- Because the functions are nice but so is not wasting time, I've added an optional switch to change where you get the absolute position from
function instanceMethods:setAbsoluteTransform(shape, tox, toy, tor, useCached)
	local attributes = self.attributes[shape]
	local parent = self.parents[shape]
	if parent then
		local fromx, fromy, fromr
		if useCached then
			local parentAttributes = self.attributes[parent]
			fromx, fromy, fromr = parentAttributes.pabsx,parentAttributes.pabsy, parentAttributes.pabsr
		else
			fromx, fromy, fromr = self:getAbsoluteTransform(parent)
		end
		attributes.relx, attributes.rely, attributes.relr = daisychain.getRequiredTransform(fromx, fromy, fromr, tox, toy, tor)
	else
		attributes.relx, attributes.rely, attributes.relr = tox, toy, tor
	end
end

function instanceMethods:getAbsoluteTransform(shape)
	local attributes = self.attributes[shape]
	local parent = self.parents[shape]
	if parent then
		local fromx, fromy, fromr = self:getAbsoluteTransform(parent)
		return daisychain.transformTransform(fromx, fromy, fromr, attributes.relx, attributes.rely, attributes.relr)
	end
	return attributes.relx, attributes.rely, attributes.relr
end

function instanceMethods:addShape(shape, hash)
	self.top[shape] = true
	self.attributes[shape] = daisychain.makeBase(shape, hash)
end

function instanceMethods:transferShape(shape, to)
	local attributes = self.attributes[shape]
	attributes.hash:remove(shape, shape:bbox())
	attributes.hash = to
	to:register(shape, shape:bbox())
	for child in pairs(self.families[object]) do
		self:transferShape(child, to)
	end
end

-- Instance-independent methods

local methodMetatable = {__index = instanceMethods}

function daisychain.new()
	return setmetatable({attributes = {}, top = {}, families = {}, parents = {}}, methodMetatable)
end

function daisychain.makeAttributes(shape, hash)
	local attributes = {hash = hash}
	if shape._type == "polygon" then
		attributes.type = "convexPolygon"
		local relx, rely = shape:center()
		attributes.relx, attributes.rely, attributes.relr = relx, rely, 0
		local base = {centroid = {x = 0, y = 0}}
		attributes.base = base
		for i, vert in ipairs(shape._polygon.vertices) do
			base[i] = {x = vert.x - relx, y = vert.y - rely}
		end
	elseif shape._type == "compound" then
		attributes.type = "concavePolygon"
		local relx, rely = shape:center()
		attributes.relx, attributes.rely, attributes.relr = relx, rely, 0
		local base = {centroid = {x = 0, y = 0}}
		attributes.base = base
		for i, vert in ipairs(shape._polygon.vertices) do
			base[i] = {x = vert.x - relx, y = vert.y - rely}
		end
		local partBases = {}
		attributes.partBases = partBases
		for i, part in ipairs(object._shapes) do
			local base = {centroid = {x = 0, y = 0}}
			partBases[i] = base
			for i, vert in ipairs(part._polygon.vertices) do
				base[i] = {x = vert.x - relx, y = vert.y - rely}
			end
		end
	elseif object._type == "circle" then
		attributes.type = "circle"
		attributes.relx, attributes.rely = object:center()
		attributes.relr = 0
	elseif object._type == "point" then
		attributes.type = "point"
		attributes.relx, attributes.rely = object:center()
		attributes.relr = 0
	else
		error("Don't know how to make attributes for shapes of type \"" .. shape._type .. "\"")
	end
	return attributes
end

function daisychain.transformCoordinates(x, y, tx, ty, r)
	local cosine, sine = cos(r), sin(r)
	return tx + x * cosine + y * sine, ty + y * cosine - x * sine
end

function daisychain.transformTransform(startx, starty, startr, newx, newy, newr)
	local cosine, sine = cos(startr), sin(startr)
	return startx + newx * cosine + newy * sine, starty + newy * cosine - newx * sine, (startr + newr) % tau
end

function daisychain.getRequiredTransform(fromx, fromy, fromr, tox, toy, tor)
	local x, y = tox - fromx, toy - fromy
	local cosine, sine = cos(fromr), sin(fromr)
	return x * cosine - y * sine, y * cosine + x * sine, (tor - fromr) % tau
end

return setmetatable(daisychain, {__call = daisychain.new})

-- Thanks for reading! :-)
