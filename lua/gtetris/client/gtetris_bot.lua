GTetris.BotPPS = 3
GTetris.RunBot = false
GTetris.AllowBotPlacing = false
GTetris.BotData = {
	board = {},
	height = 0,
	height_raw = 0,
	height_half = 0,
	combo = 0,
	piece = -1,
	holdpiece = -1,
	holdused = false,
	ruleset = {},
	nextpieces = {},
}

local nextExec = 0
hook.Add("Think", "GTetris_BotProcessing", function()
	local systime = SysTime()
	local localplayer = GTetris.GetLocalPlayer()
	if(!GTetris.RunBot || nextExec > systime || !IsValid(localplayer)) then return end
	nextExec = systime + (1 / GTetris.BotPPS)
	local board = GTetris_CloneBoard(localplayer.CurrentBoard)
	local st = SysTime()

	GTetris.BotData.board = board
	GTetris.BotData.piece = localplayer.CurrentPiece
	GTetris.BotData.holdpiece = localplayer.CurrentHoldPiece
	GTetris.BotData.canhold = localplayer.HoldUsed
	GTetris.BotData.ruleset = GTetris.Rulesets
	GTetris.BotData.combo = localplayer.CurrentCombo
	local st = SysTime()
	local result = GTetris_FindSolution(GTetris.BotData)
	print("Finding solution in "..math.Round(SysTime() - st, 5).."s")

	localplayer.PieceSize = ScreenScaleH(16)
	localplayer.PostRender = function(board)
		if(!result) then
			return
		end
		local shape = result.shape
		for i = 1, #shape do
			local x = (shape[i][1] + result.x) * localplayer.PieceSize
			local y = (shape[i][2] + result.y) * localplayer.PieceSize
			local color = GTetris.Blocks_Colors[localplayer.CurrentPiece]
			draw.RoundedBox(0, x, y, localplayer.PieceSize, localplayer.PieceSize, Color(color.r, color.g, color.b, 30))
		end

		local PlaceY = GTetris.TraceToBottom(localplayer)
		local PlaceX = localplayer.CurrentPosition.x
		local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
		local rotation = localplayer.CurrentRotationState
		local piece = localplayer.CurrentPiece

		local gap = ScreenScaleH(16)
		draw.DrawText("Score : "..GTetris_Evaluate(GTetris.BotData, GTetris_CloneBoard(localplayer.CurrentBoard), PlaceX, PlaceY, shape, piece, rotation), "GTetris-UISmall2x", 0, -gap, color_white, TEXT_ALIGN_RIGHT)
	end

	if(GTetris.AllowBotPlacing) then
		local shape = result.shape
		local PlaceY = result.y
		local PlaceX = result.x
		for _, block in ipairs(shape) do
			local x = block[1] + PlaceX
			local y = block[2] + PlaceY
			localplayer.CurrentBoard[y][x] = localplayer.CurrentPiece
		end
		GTetris.PlacePiece(localplayer, true)
	end
end)