GTetris_BotAttr_Beam_Search_Depth = 3
GTetris_BotAttr_Lookahead_Depth = 3

GTetris_BotAttr_b2b = 52
GTetris_BotAttr_bumpiness = -24
GTetris_BotAttr_bumpiness_sq = -7
GTetris_BotAttr_row_transitions = -5
GTetris_BotAttr_height = -39
GTetris_BotAttr_top_half = -150
GTetris_BotAttr_top_quarter = -511
GTetris_BotAttr_jeopardy = -11
GTetris_BotAttr_cavity_cells = -173
GTetris_BotAttr_cavity_cells_sq = -3
GTetris_BotAttr_overhang_cells = -34
GTetris_BotAttr_overhang_cells_sq = -1
GTetris_BotAttr_covered_cells = -17
GTetris_BotAttr_covered_cells_sq = -1
GTetris_BotAttr_tslot = {8, 148, 192, 407}
GTetris_BotAttr_well_depth = 57
GTetris_BotAttr_max_well_depth = 17
GTetris_BotAttr_well_column = {20, 23, 20, 50, 59, 21, 59, 10, -10, 24}

GTetris_BotAttr_wasted_t = -152
GTetris_BotAttr_b2b_clear = 104
GTetris_BotAttr_clear1 = -143
GTetris_BotAttr_clear2 = -100
GTetris_BotAttr_clear3 = -58
GTetris_BotAttr_clear4 = 390
GTetris_BotAttr_tspin1 = 121
GTetris_BotAttr_tspin2 = 410
GTetris_BotAttr_tspin3 = 630
GTetris_BotAttr_tspin4 = 870
GTetris_BotAttr_allclear = 1000
GTetris_BotAttr_combo_attack = 150

function GTetris_CloneBoard(board)
	local newBoard = {}
	for i = -5, #board do
		newBoard[i] = {}
		for j = 0, #board[i] do
			newBoard[i][j] = board[i][j]
		end
	end
	return newBoard
end

function GTetris_PrintBoard(board)
	for i = 0, #board do
		local line = ""
		for j = 0, #board[i] do
			line = line .. board[i][j] .. " "
		end
	end
end

function GTetris_GetBoardHeight(board)
	local height = 0
	for i = -5, #board do
		for j = 0, #board[i] do
			if(board[i][j] != 0) then
				return #board - (i - 1), i
			end
		end
	end
	return 0, #board
end

function GTetris_Placeable(board, shape, x, y)
	local onground = false
	for _, block in ipairs(shape) do
		local x = (block[1] + x)
		local y = (block[2] + y)
		if(!board[y] || !board[y][x] || board[y][x] != 0) then
			return false
		end

		if(!board[y + 1] || board[y + 1][x] != 0) then
			onground = true
		end
	end
	return onground
end

local offsets = {
	[1] = {0, -1},
	[2] = {-1, 0},
	[3] = {0, 1},
	[4] = {1, 0},
}
function GTetris_CheckBonus(board, shape, x, y)
	local bonus = true
	for _, offset in ipairs(offsets) do
		local x = x + offset[1]
		local y = y + offset[2]
		if(GTetris.TestCollision(board, shape, x, y)) then
			bonus = false
			break
		end
	end
	return bonus
end

function GTetris_SimulatePlace(board, x, y, shape, piece)
	for _, block in ipairs(shape) do
		local _x = block[1] + x
		local _y = block[2] + y
		board[_y][_x] = piece
	end
end

--[[
	board = {},
	combo = 0,
	height = 0,
	height_raw = 0,
	height_half = 0,
	piece = -1,
	holdpiece = -1,
	holdused = false,
	ruleset = {},
]]

function GTetris_CheckClearLine(board, width, height)
	local lineCleared = 0
	for i = -20, height, 1 do
		local rows = board[i]
		if(!rows) then continue end
		local clear = true
		for col = 0, width do
			local id = rows[col]
			if(id == 0) then
				clear = false
			end
		end
		
		if(clear) then
			lineCleared = lineCleared + 1
		end
	end

	return lineCleared
end

function GTetris_ColumnHeight(board, col)
	for i = -4, #board do
		if(board[i][col] != 0) then
			return #board - (i - 1), i
		end
	end
	return 0, #board
end

function GTetris_Cavities_And_Overhangs(board)
	local cavities = 0
	local overhangs = 0
	local h, raw = GTetris_GetBoardHeight(board)
	for y = #board, raw, -1 do
		local rows = board[y]
		for x = 0, #rows do
			local _, height = GTetris_ColumnHeight(board, x)
			if(GTetris_Occupied(board, x, y) || (raw > height)) then
				continue
			end
			if(GTetris_Occupied(board, x, y - 1)) then
				if(x == 0) then
					--[[
						XOO
						OOO
					]]
					if(GTetris_Occupied(board, x + 1, y)) then
						overhangs = overhangs + 1
						continue
					end
				elseif(x == #rows) then
					--[[
						OOX
						OOO
					]]
					if(GTetris_Occupied(board, x - 1, y)) then
						overhangs = overhangs + 1
						continue
					end
				else
					--[[
						OXO
						OOX
						or
						OXO
						XOO
					]]
					local a, b = GTetris_Occupied(board, x - 1, y), GTetris_Occupied(board, x + 1, y)
					if((a || b) && !(a && b)) then -- xor
						overhangs = overhangs + 1
						continue
					end
				end
			end
			cavities = cavities + 1
		end
	end
	return cavities, overhangs
end

function GTetris_CoveredHoles(board)
	local covered = 0
	local h, raw = GTetris_GetBoardHeight(board)
	for y = #board, raw, -1 do
		if(y == raw) then continue end
		for x = 0, #board[y] do
			if(GTetris_Occupied(board, x, y)) then
				continue
			end
			local _, height = GTetris_ColumnHeight(board, x)
			covered = covered + math.min(math.max(y - height, 0), 6)
		end
	end
	return covered
end

function GTetris_GetBumpiness(board, w, well)
	local bumpiness = -1
	local prev = 0

	for i = 0, w do
		if(i == well) then
			continue
		end
		local diff = math.abs(GTetris_ColumnHeight(board, prev) - GTetris_ColumnHeight(board, i))
		bumpiness = bumpiness + diff
		prev = i
	end

	return bumpiness
end

function GTetris_Occupied(board, x, y)
	return board[y][x] != 0
end

--[[
	local board = GTetris.GetLocalPlayer().CurrentBoard
	local well = 0
	local highestpoint = 0
	for i = 0, 9 do
		local height = GTetris_ColumnHeight(board, i)
		if(height > highestpoint) then
			highestpoint = height
		end
		if(height >= GTetris_ColumnHeight(board, well)) then
			well = i
		end
	end
	print(well)
]]

function GTetris_Evaluate(bot, x, y, shape, piece, rotation)

end

function GTetris_FindSolution(bot)
	local board = bot.board
	local height = bot.height
	local height_raw = bot.height_raw
	local height_half = bot.height_half
	local piece = bot.piece
	local holdpiece = bot.holdpiece
	local holdused = bot.holdused
	local combo = bot.combo
	local ruleset = bot.ruleset
	local lookahead = {}

	bot.havet = holdpiece == GTetris.Block_T
	for _, piece in ipairs(bot.nextpieces) do
		if(piece == GTetris.Block_T) then
			bot.havet = true
			break
		end
	end

	--[[
	for i = 1, GTetris_BotAttr_Lookahead_Depth do
		lookahead[i] = {}
	end
	]]

	local wide = ruleset.Width - 1
	for col = #board, height_raw - 3, -1 do
		for row = 0, wide do
			for rotation = 1, 4 do
				local shape = GTetris_Blocks[piece][rotation]
				if(!GTetris_Placeable(board, shape, row, col)) then
					continue
				else

				end
			end
		end
	end

end