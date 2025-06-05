GTetris.Wallkicks = {
	[1] = {
		[1] = { -- Not I
			["01"] = {{1, -1},{-1, 0},{-1, 1},{0, -2},{-1, -2}},
			["10"] = {{1, 0},{1, -1},{0, 2},{1, 2}, {-1, -1}},
			["12"] = {{1, 0},{1, -1},{0, 2},{1, 2}},
			["21"] = {{1, 1},{-1, 0},{-1, 1},{0, -2},{0, 1},{-1, -2}},
			["23"] = {{0, 1},{1, 0},{1, 1},{0, -2},{1, -2},{-2, 1},},
			["32"] = {{2, 0},{0, -1},{2, -1},{-1, 0},{-1, -1},{0, 2},{-1, 2}},
			["30"] = {{2, 0},{2, 1},{-1, 0},{-1, -1},{0, 2},{-1, 2}},
			["03"] = {{0, -1},{1, 0},{1, 1},{0, -2},{1, -2}, {1, -1},{-2, -1},},
			["13"] = {{0, 1},{0, -1},{1, 0},{-1, 0},},
			["31"] = {{0, -1},{0, 1},{-1, 0},{1, 0},},
			["02"] = {{2, -2},{2, 2},{2, 0},{-1, 0},{1, 0},{0, -1},{0, 1},},
			["20"] = {{1, 0},{-1, 0},{0, 1},{0, -1},},
		},
		[2] = { -- I
			["01"] = {{-2, 0},{1, 0},{1, 2},{-2, -1}},
			["10"] = {{2, 0},{-1, 0},{2, 1},{-1, -2}},
			["12"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["21"] = {{1, 0},{-2, 0},{1, -2},{-2, 1}},
			["23"] = {{2, 0},{-1, 0},{2, 1},{-1, -2}},
			["32"] = {{0, 1},{-2, 0},{1, 0},{-2, -1},{1, 2}},
			["30"] = {{1, 0},{-2, 0},{1, -2},{-2, 1}},
			["03"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["13"] = {{0, 1},{0, -1},{1, 0},{-1, 0},},
			["31"] = {{0, -1},{0, 1},{-1, 0},{1, 0},},
		}
	},
	[2] = {
		[1] = { -- Not I
			["01"] = {{-2, 0},{1, 0},{1, 2},{-2, -1}},
			["10"] = {{2, 0},{-1, 0},{2, 1},{-1, -2}},
			["12"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["21"] = {{-2, 0},{1, 0},{-2, 1},{1, -1}},
			["23"] = {{2, 0},{-1, 0},{2, 1},{-1, -1}},
			["32"] = {{1, 0},{-2, 0},{1, 2},{-2, -1}},
			["30"] = {{1, 0},{-2, 0},{1, -2},{-2, 1}},
			["03"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["13"] = {{0, 1},{0, -1},{1, 0},{-1, 0},},
			["31"] = {{0, -1},{0, 1},{-1, 0},{1, 0},},
		},
		[2] = { -- I
			["01"] = {{-2, 0},{1, 0},{1, 2},{-2, -1}},
			["10"] = {{2, 0},{-1, 0},{2, 1},{-1, -2}},
			["12"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["21"] = {{-2, 0},{1, 0},{-2, 1},{1, -1}},
			["23"] = {{2, 0},{-1, 0},{2, 1},{-1, -1}},
			["32"] = {{1, 0},{-2, 0},{1, 2},{-2, -1}},
			["30"] = {{1, 0},{-2, 0},{1, -2},{-2, 1}},
			["03"] = {{-1, 0},{2, 0},{-1, 2},{2, -1}},
			["13"] = {{0, 1},{0, -1},{1, 0},{-1, 0},},
			["31"] = {{0, -1},{0, 1},{-1, 0},{1, 0},},
		}		
	}
}

local offsets = {
	[1] = {0, -1},
	[2] = {-1, 0},
	[3] = {0, 1},
	[4] = {1, 0},
}

--[[
	{
		title = "T-Spin",
		value = GTetris.Enums.ALLOWEDSPINS_TSPIN,
	},
	{
		title = "All",
		value = GTetris.Enums.ALLOWEDSPINS_ALL,
	},
	{
		title = "None",
		value = GTetris.Enums.ALLOWEDSPINS_NONE,
	},
	{
		title = "Everything is a spin",
		value = GTetris.Enums.ALLOWEDSPINS_STUPID,
	},
]]

function GTetris.CheckBonus(board, piece, shape, origin, ruleset)
	if(ruleset == 1) then
		if(piece != GTetris.Block_T) then
			return false
		end
	elseif(ruleset == 3) then
		return false
	elseif(ruleset == 4) then
		return true
	end
	local bonus = true
	for _, offset in ipairs(offsets) do
		local x = origin.x + offset[1]
		local y = origin.y + offset[2]
		if(GTetris.TestCollision(board, shape, x, y)) then
			bonus = false
			break
		end
	end
	return bonus
end

function GTetris_CheckBonus(board, shape, x, y)
	local bonus = true
	for _, offset in ipairs(offsets) do
		local x = x + offset[1]
		local y = y + offset[2]
		if(GTetris_TestCollision(board, shape, x, y)) then
			bonus = false
			break
		end
	end
	return bonus
end

function GTetris.ProcessRotation(board, piece, rule, shape, x, y, last, new, localplayer)
	local wallkickSystem = GTetris.Wallkicks[rule]
	if(GTetris.TestCollision(board, shape, x, y)) then
		return true
	end
	if(wallkickSystem) then
		local type = 1
		if(piece == 1) then
			type = 2
		end
		local wallkick = wallkickSystem[type]
		local rotationKey = tostring(last - 1)..tostring(new - 1)
		local KickTable = wallkick[rotationKey]
		if(!KickTable) then
			return false
		end
		for _, move in ipairs(KickTable) do
			local newX = x + move[2]
			local newY = y + move[1]
			if(GTetris.TestCollision(board, shape, newX, newY)) then
				localplayer.CurrentPosition.x = newX
				localplayer.CurrentPosition.y = newY
				return true
			end
		end
	else -- Classic
		return false
	end
end