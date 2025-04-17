function GTetris.TestCollision(board, shape, x, y)
	for _, block in ipairs(shape) do
		local x = (block[1] + x)
		local y = (block[2] + y)
		if(board[y] == nil || board[y][x] == nil || board[y][x] != 0) then
			return false
		end
	end
	return true
end

function GTetris.ClearRow(board, row, width)
	for col = 0, width do
		board[row][col] = 0
	end
end

function GTetris.MoveRowDown(board, startfrom, width)
	for i = startfrom, -20, -1 do
		local pRow = i - 1
		if(pRow <= -20) then
			GTetris.ClearRow(board, i, width)
		else
			board[i] = table.Copy(board[pRow])
		end
	end
end

function GTetris.MoveRowUp(board, amount, width, height)
	local MaxRange = height - 1
	local ColumanToFill = MaxRange - amount
	local RandGap = math.random(0, width - 1)
	local RandCol = {}
	for i = 0, width - 1 do
		if(i != RandGap) then
			RandCol[i] = 8
		else
			RandCol[i] = 0
		end
	end
	for i = -20, MaxRange, 1 do
		local nextCol = board[i + amount]
		if(nextCol) then
			board[i] = table.Copy(nextCol)
		end
		if(i > ColumanToFill) then
			board[i] = table.Copy(RandCol)
		end	
	end
end

function GTetris.CheckClearLine(board, width, height)
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
		
		if(clear && i > -20) then
			GTetris.ClearRow(board, i, width)
			GTetris.MoveRowDown(board, i, width)
			lineCleared = lineCleared + 1
		end
	end

	return lineCleared
end

function GTetris.CheckAllClear(board, width, height)
	for i = -20, height, 1 do
		local rows = board[i]
		if(!rows) then continue end
		for col = 0, width do
			local id = rows[col]
			if(id != 0) then
				return false
			end
		end
	end
	return true
end