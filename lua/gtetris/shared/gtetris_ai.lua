local table_insert = table.insert
local abs = math.abs

GTetris_Bot_Attr_Flat = 3
GTetris_Bot_Attr_Bumpiness = -2
GTetris_Bot_Attr_Deviation = -4

GTetris_Bumpiness_Inc = {
	1,
	3,
	7,
	7,
}

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

function GTetris_Placeable(board, shape, x, y, w, h)
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

function GTetris_ColumnHeight(board, col)
	for i = -4, #board do
		if(board[i][col] != 0) then
			return #board - (i - 1), i
		end
	end
	return 0, #board
end

function GTetris_GetBoardHeight(board)
	local height = 0
	for i = -4, #board do
		for j = 0, #board[i] do
			if(board[i][j] != 0) then
				return i
			end
		end
	end
	return #board
end

function GTetris_SimulatePlace(board, x, y, shape, piece)
	for _, block in ipairs(shape) do
		local _x = block[1] + x
		local _y = block[2] + y
		board[_y][_x] = piece
	end
end

function GTetris_PrintBoard(board)
	local str = ""
	for y = -20, #board do
		if(!board[y]) then
			continue
		end
		for x = 0, #board[y] do
			if(x == 0) then
				str = str..y.." | : "
			end
			str = str..(board[y][x] || 0)
		end
		str = str.."\n"
	end
	print("--")
	print(str)
	print("--")
end

function GTetris_FindCoveredHoles(board, maxtall)
	local holes = 0
	for y = #board, maxtall, -1 do
		for x = 0, #board[y] do
			local cell = board[y][x]
			local cell2 = board[y - 1]
			if(cell == 0 && cell2 && cell2[x] != 0) then
				holes = holes + 1
			end
		end
	end
	return holes
end

function GTetris_Evaluate(bot, oboard, x, y, shape, piece, rotation)
	local board = GTetris_CloneBoard(oboard)
	local w, h = bot.ruleset.Width - 1, bot.ruleset.Height - 1
	GTetris_SimulatePlace(board, x, y, shape, piece)
	local line_cleared = GTetris_CheckClearLine(board, bot.ruleset.Width - 1, bot.ruleset.Height - 1)
	local maxtall = GTetris_GetBoardHeight(board)
	local score = 0
	local lowest = -1
	local lowest_height = -1
	local talls = {}

	--取目前最低列並快取每列的高度
	for row = 0, w do
		local tall, tall_raw = GTetris_ColumnHeight(board, row)
		if(lowest == -1 || tall < lowest_height) then
			lowest = row
			lowest_height = tall
		end
		talls[row] = {tall, tall_raw}
	end



	return score
end

function GTetris_DecideMove(bot)
	local w, h = bot.ruleset.Width - 1, bot.ruleset.Height - 1
	local tall = GTetris_GetBoardHeight(bot.board) - 4
	local board = bot.board
	local shapes = GTetris.Blocks
	local piece = bot.piece
	local results = {}
	for x = -2, w do
		for y = h, tall, -1 do
			for r = 1, 4 do
				local shape = shapes[piece][r]
				if(!GTetris_Placeable(board, shape, x, y, w, h)) then
					continue
				end
				table_insert(results, {
					shape = shape,
					x = x,
					y = y,
					rotation = r,
					score = GTetris_Evaluate(bot, board, x, y, shape, piece, r)
				})
			end
		end
	end

	table.sort(results, function(a, b)
		return a.score > b.score
	end)
	return results[1]
end

function GTetris_FindSolution(bot)
	local result1 = GTetris_DecideMove(bot)

	return result1
end