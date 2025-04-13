function GTetris.MovePiece(localplayer, x, y)
	local origin = localplayer.CurrentPosition
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	if(GTetris.TestCollision(localplayer.CurrentBoard, shape, origin.x + x, origin.y + y)) then
		localplayer.CurrentPosition.x = origin.x + x
		localplayer.CurrentPosition.y = origin.y + y
	end
end

function GTetris.TraceToBottom(localplayer)
	local x = localplayer.CurrentPosition.x
	local y = localplayer.CurrentPosition.y
	local bottom = GTetris.Rulesets.Height - 1
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	local board = localplayer.CurrentBoard
	for i = y, bottom do
		if(!GTetris.TestCollision(board, shape, x, i)) then
			return i - 1
		end
	end
end

function GTetris.PlacePiece(localplayer)
	local PlaceX = localplayer.CurrentPosition.x
	local PlaceY = GTetris.TraceToBottom(localplayer)
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	local board = localplayer.CurrentBoard
	for _, block in ipairs(shape) do
		local x = block[1] + PlaceX
		local y = block[2] + PlaceY
		board[y][x] = localplayer.CurrentPiece
	end

	table.remove(localplayer.CurrentPieces, 1)
	localplayer.CurrentPiece = localplayer.CurrentPieces[1]
	localplayer.CurrentPosition.x = math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[localplayer.CurrentPiece]) / 2)
	localplayer.CurrentPosition.y = 0
	localplayer.CurrentRotationState = 4

	if(#localplayer.CurrentPieces <= 6) then
		local newPieces = GTetris.GeneratePieces(GTetris.Rulesets.BagSystem, localplayer.CurrentSeed)
		table.Add(localplayer.CurrentPieces, newPieces)
		localplayer.CurrentSeed = localplayer.CurrentSeed + 1
	end

	local lineCleared = GTetris.CheckClearLine(localplayer.CurrentBoard, GTetris.Rulesets.Width - 1, GTetris.Rulesets.Height - 1)
	localplayer.Bonus = false
	localplayer.HoldUsed = false
end