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