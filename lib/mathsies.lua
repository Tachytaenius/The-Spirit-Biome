local metadata = {
	name = "Mathsies",
	description = "Deterministic maths functions for LuaJIT.",
	version = "0.1.0",
	author = "Tachytaenius",
	license = [[
		MIT License
		
		Copyright (c) 2018 Henry Fleminger Thomson
		
		Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
		
		The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	]]
}

-- TODO: Just the things that need to be done (the not-already-deterministic ones). Ie remove the stuff beyond the FIXME

-- TODO: Logarithms, exponentiation

local tau = 6.28318530717958647692
local phi = 1.61803398874989484820
local sqrt, abs, floor, ceil, min, max, huge = math.sqrt, math.abs, math.floor, math.ceil, math.min, math.max, math.huge

local function sin(x)
	local over = floor(x / (tau/2)) % 2 == 0 -- Is the sinusoid over or under at this x?
	x = abs(x) % (tau/2) -- Boil it down to what matters
	local absolute = (32*x*(tau-2*x))/(5*tau^2+16*x^2-8*tau*x) -- Bhāskara I's sine approximation in terms of tau.
	return over and absolute or -absolute
end

local function asin(x)
	if x < -1 or x > 1 then
		error("x must be within [-1, 1]")
	end
	-- Formula given by Blue on Mathematics Stack Exchange. https://math.stackexchange.com/users/409/blue
	local resultForAbsoluteX = tau / 4*(1-2*sqrt((1-abs(x))/(4+abs(x))))
	return x < 0 and -resultForAbsoluteX or resultForAbsoluteX
end

local function cos(x)
	return sin(tau / 4 - x)
end

local function acos(x)
	return tau / 4 - asin(x)
end

local function tan(x)
	return sin(x)/cos(x)
end

local function atan(x)
	return asin(x/sqrt(1+x^2))
end

local function cot(x)
	return cos(x)/sin(x)
end

local function acot(x)
	return acos(x/sqrt(1+x^2))
end


-- FIXME: Inappropriate content herein

local function angleDifference(a, b)
	return (a - b + tau / 2) % tau - tau / 2
end

local function distance(x, y)
	return sqrt(x^2 + y^2)
end

local function angle(x, y)
	x = x == 0 and 1 or x
	local a = atan(y/x)
	a = x < 0 and a + tau / 2 or a
	return a % tau
end

local function cartesianToPolar(x, y)
	return distance(x, y), angle(x, y)
end

local function polarToCartesian(r, theta)
	local x = r * cos(theta)
	local y = r * sin(theta)
	return x, y
end

local function round(x, y)
	y = y or 1
	return floor(x * y + 0.5) / y
end

local function sgn(x)
	-- Did you hear about the mathematician who was afraid of negative numbers?
	-- He'd stop at nothing to avoid them.
	return x == 0 and 0 or abs(x) / x
	-- Did you laugh at that? I hope you didn't, because zero is a number; the empty set is when things get nothingy.
	-- "Zero is the cardinality of nothing, therefore zero is nothing." As if.
end

local function isInteger(x)
	return floor(x) == x
end

local function closestPointOnCircumference(px, py, cx, cy, r)
	local vx, vy = px - cx, py - cy
	local vl = distance(vx, vy) -- get length of vector from point to circle centre
	local ax, ay = cx + vx / vl * r, cy + cy / vl * r
	return ax, ay -- return the answer
end

local function int(a, b, f, n)
	n = n or 256
	a, b = min(a, b), max(a, b)
	local sum = 0
	for v = a, b - (b - a) / n, (b - a) / n do
		sum = sum + f(v) * (b - a) / n
	end
	return sum
end

local function tri(x)
	return abs((x-tau/4)%tau-tau/2)/(tau/4)-1
end

local function real(x)
	return x == x and abs(x) ~= huge
end

local function isNan(x)
	return x ~= x
end

local function isInfinite(x)
	return abs(x) == huge
end

local function clamp(lower, x, upper)
	return max(lower, min(x, upper))
end

local function dot(x1,y1,x2,y2)
	return x1*x2 + y1*y2
end

local function segmentPointDistance(vx, vy, wx, wy, px, py)
	local lengthSquared = distance(wx-vx, wy-vy) ^ 2
	if lengthSquared == 0 then return distance(vx-px, vy-py) end
	local t = clamp(0, dot(px-vx, py-vy, wx-vx, wy-vy) / lengthSquared, 1)
	local projectionX = vx + t * (wx - vx)
	local projectionY = vy + t * (wy - vy)
	return distance(px-projectionX, py-projectionY)
end

return {
	metadata = metadata,
	
	tau = tau,
	phi = phi,
	pi = tau / 2, -- LuaJIT will optimise "tau / 2" in code, so choose whichever you find personally gratifying. I use tau in this library.
	sin = sin,
	asin = asin,
	cos = cos,
	acos = acos,
	tan = tan,
	atan = atan,
	cot = cot,
	acot = acot,
	angleDifference = angleDifference,
	int = int,
	distance = distance,
	angle = angle,
	cartesianToPolar = cartesianToPolar,
	polarToCartesian = polarToCartesian,
	round = round,
	sgn = sgn,
	isInteger = isInteger,
	closestPointOnCircumference = closestPointOnCircumference,
	sqrt = sqrt,
	abs = abs,
	ceil = ceil,
	floor = floor,
	max = max,
	min = min,
	huge = huge,
	tri = tri,
	real = real,
	isNan = isNan,
	isInfinite = isInfinite,
	clamp = clamp,
	dot = dot,
	segmentPointDistance = segmentPointDistance,
	
	-- non-deterministic but faster, for use in graphics
	ndCos = math.cos,
	ndSin = math.sin,
	ndTan = math.tan,
	ndAcos = math.acos,
	ndAsin = math.asin,
	ndAtan = math.atan,
	ndLog = math.log,
	ndRandom = math.random
}

-- thanks for reading :-)

--[[some sort of TODO?
local tau = 6.28318530717958647692
local sqrt, abs, floor = math.sqrt, math.abs, math.floor

local function sin(x)
	local over = floor(x / (tau/2)) % 2 == 0 -- Is the sinusoid over or under at this x?
	x = abs(x) % (tau/2) -- Boil it down to what matters
	local absolute = (32*x*(tau-2*x))/(5*tau^2+16*x^2-8*tau*x) -- Bhāskara I's sine approximation in terms of tau.
	return over and absolute or -absolute
end 

local function asin(x)
	if x < -1 or x > 1 then
		error("x must be within [-1, 1]")
	end
	-- Formula given by Blue on Mathematics Stack Exchange. https://math.stackexchange.com/users/409/blue
	local resultForAbsoluteX = tau / 4*(1-2*sqrt((1-abs(x))/(4+abs(x))))
	return x < 0 and -resultForAbsoluteX or resultForAbsoluteX
end

local function cos(x)
	return sin(tau / 4 - x)
end

local function acos(x)
	return tau / 4 - asin(x)
end

local function tan(x)
	return sin(x)/cos(x)
end

local function atan(x)
	return asin(x/sqrt(1+x^2))
end

local function cot(x)
	return cos(x)/sin(x)
end

local function acot(x)
	return acos(x/sqrt(1+x^2))
end

local mathsies = {}
for k, v in pairs(math) do
	mathsies[k] = v
end

mathsies.tau = tau
mathsies.pi, mathsies._pi = tau / 2, mathsies.pi
mathsies.sin, mathsies._sin = sin, mathsies.sin
mathsies.asin, mathsies._asin = asin, mathsies.asin
mathsies.cos, mathsies._cos = cos, mathsies.cos
mathsies.acos, mathsies._acos = acos, mathsies.acos
mathsies.tan, mathsies._tan = tan, mathsies.tan
mathsies.atan, mathsies._atan = atan, mathsies.atan
mathsies.cot, mathsies.acot = cot, acot

return mathsies
]]
