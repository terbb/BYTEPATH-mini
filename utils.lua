-- Misc
function UUID()
    local fn = function(x)
        local r = love.math.random(16) - 1
        r = (x == "x") and (r + 1) or (r % 4) + 9
        return ("0123456789abcdef"):sub(r, r)
    end
    return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end

function random(min, max)
    local min, max = min or 0, max or 1
    return (min > max and (love.math.random()*(min - max) + max)) or (love.math.random()*(max - min) + min)
end

function returnTableLength(t)
	local i = 0
	for _, _ in pairs(t) do
		i = i + 1
	end
	return i
end

-- Does not work with tables that do not use integers as keys!
function table.random(t)
    return t[love.math.random(1, returnTableLength(t))]
end

function table.copy(t)
    local copy
    if type(t) == 'table' then
        copy = {}
        for k, v in next, t, nil do copy[table.copy(k)] = table.copy(v) end
        setmetatable(copy, table.copy(getmetatable(t)))
    else copy = t end
    return copy
end

function chanceList(...)
    return {
    	chance_list = {},
    	chance_definitions = {...},
		next = function(self)
			if #self.chance_list == 0 then
				for _, chance_definition in ipairs(self.chance_definitions) do
					for i = 1, chance_definition[2] do 
						table.insert(self.chance_list, chance_definition[1]) 
					end
				end
			end
			return table.remove(self.chance_list, love.math.random(1, #self.chance_list))
		end
    }
end

function selectRandomKey(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys[love.math.random(1, #keys)]
end

function returnAllKeys(t)
	local keys = {}
	for key, _ in pairs(t) do
		table.insert(keys, key)
	end
	return keys
end

function table.merge(t1, t2)
    local new_table = {}
    for k, v in pairs(t2) do new_table[k] = v end
    for k, v in pairs(t1) do new_table[k] = v end
    return new_table
end

-- Memory leak checking

function count_all(f)
    local seen = {}
    local count_table
    count_table = function(t)
        if seen[t] then return end
            f(t)
	    seen[t] = true
	    for k,v in pairs(t) do
	        if type(v) == "table" then
		    count_table(v)
	        elseif type(v) == "userdata" then
		    f(v)
	        end
	end
    end
    count_table(_G)
end

function type_count()
    local counts = {}
    local enumerate = function (o)
        local t = type_name(o)
        counts[t] = (counts[t] or 0) + 1
    end
    count_all(enumerate)
    return counts
end

global_type_table = nil
function type_name(o)
    if global_type_table == nil then
        global_type_table = {}
            for k,v in pairs(_G) do
	        global_type_table[v] = k
	    end
	global_type_table[0] = "table"
    end
    return global_type_table[getmetatable(o) or 0] or "Unknown"
end

-- Graphics transformations

function pushTranslate(x, y)
	love.graphics.push()
    love.graphics.translate(x, y)
end

function pushRotate(x, y, r)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(r or 0)
    love.graphics.translate(-x, -y)
end

function pushRotateScale(x, y, r, sx, sy)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(r or 0)
    love.graphics.scale(sx or 1, sy or sx or 1)
    love.graphics.translate(-x, -y)
end

-- Gameplay

function slow(amount, duration)
    slow_amount = amount
    timer:tween('slow', duration, _G, {slow_amount = 1}, 'in-out-cubic')
end

-- Used to fade in the entire screen.
function fade_in(duration)
	screen_alpha = 0
	timer:tween('fade_in', duration, _G, {screen_alpha = 1}, 'in-out-cubic')
end

-- Used to fade out the entire screen.
function fade_out(duration)
	screen_alpha = 1
	timer:tween('fade_in', duration, _G, {screen_alpha = 0}, 'in-out-cubic')	
end

-- Use instead of love.graphics.setColor for fading in and fading out.
function setColor(r, g, b, a)
	--[[
		If fading in ( from black) is happening:
			- If screen alpha is lower than the given alpha, keep increasing it and set it to screen alpha
			- If screen alpha is greater than or equal to the given alpha at this point, just set it to alpha
			
		If fading out ( to black) is happening:
			- If screen alpha is greater than or equal to the given alpha, just set it to alpha
			- If screen alpha is lower than the given alpha, keep decreasing it and set it to screen alpha
	]]--
	if screen_alpha < a then
		love.graphics.setColor(r, g, b, screen_alpha)
	else
		love.graphics.setColor(r, g, b, a)
	end
end

function flash(seconds)
    flash_seconds = seconds
end

function distance(x1, y1, x2, y2)
    return math.sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2))
end