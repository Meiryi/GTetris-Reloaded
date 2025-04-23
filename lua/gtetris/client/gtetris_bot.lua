GTetris.BotPPS = 2
GTetris.RunBot = true
GTetris.AllowBotPlacing = true
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
	local board = GTetris_CloneBoard(localplayer.CurrentBoard)
	GTetris.BotData.board = board
	GTetris.BotData.height, GTetris.BotData.height_raw = GTetris_GetBoardHeight(board)
	GTetris.BotData.height_half = math.floor(GTetris.BotData.height / 2)
	GTetris.BotData.combo = localplayer.CurrentCombo
	GTetris.BotData.piece = localplayer.CurrentPiece
	GTetris.BotData.holdpiece = localplayer.CurrentHoldPiece
	GTetris.BotData.holdused = localplayer.HoldUsed
	GTetris.BotData.ruleset = GTetris.Rulesets
	GTetris.BotData.nextpieces = localplayer.CurrentPieces

	local st = SysTime()
	local result = GTetris_FindSolution(GTetris.BotData) || {}
	print("Finding solution in: " .. math.Round((SysTime() - st), 4) .. "s")
	localplayer._x = result[3] || 0
	localplayer._y = result[4] || 0
	localplayer.piece = result[5] || 1
	localplayer.rotation = result[6] || 1
	localplayer.PieceSize = ScreenScaleH(16)
	localplayer.PostRender = function(board)
		local shape = GTetris.Blocks[localplayer.piece][localplayer.rotation]
		local color = GTetris.Blocks_Colors[localplayer.piece]
		for i = 1, #shape do
			local x = (shape[i][1] + localplayer._x) * localplayer.PieceSize
			local y = (shape[i][2] + localplayer._y) * localplayer.PieceSize
			draw.RoundedBox(0, x, y, localplayer.PieceSize, localplayer.PieceSize, Color(color.r, color.g, color.b, 30))
		end
	end

	nextExec = systime + (1 / GTetris.BotPPS)
end)