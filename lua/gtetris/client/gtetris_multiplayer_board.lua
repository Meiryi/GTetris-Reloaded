function GTetris.PlayWinnerAnimSequence(winnerName)
	if(!IsValid(GTetris.MainUI)) then return end
	local scrw, scrh = ScrW(), ScrH()
	local layer = GTetris.CreatePanel(GTetris.MainUI, 0, 0, scrw, scrh, color_transparent)
		
end

function GTetris.PlayAbortAnimSequence(winnerName)

end

net.Receive("GTetris.InitBoardLayer", function(length, sender)
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local roomdata = GTetris.DecompressTable(data)
	local players = {}
	for _, ply in ipairs(player.GetAll()) do
		players[ply:GetCreationID()] = ply
	end
	local BaseUI = GTetris.MainUI
	local layer = GTetris.SetupBoardLayer(BaseUI)
	layer.Multiplayer = true
	GTetris.ApplyRulesets(roomdata.ruleset)

	for _, ply in pairs(roomdata.players) do
		local player = players[ply.playerID]
		if(ply.Bot) then
		else
			if(player == LocalPlayer()) then
				local id = tostring(ply.playerID)
				local board = GTetris.CreateBoard(id, true)
				layer.LocalPlayerID = id
				board.PlayerNick = ply.nick
			else
				local id = tostring(ply.playerID)
				local board = GTetris.CreateBoard(id)
				board.PlayerNick = ply.nick
			end
		end
	end

	GTetris.SortBoards(true)
end)

net.Receive("GTetris.SendAttack", function(length, sender)
	
end)