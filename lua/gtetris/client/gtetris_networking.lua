function GTetris.IsInMultiplayerGame()
	return IsValid(GTetris.BoardLayer) && GTetris.BoardLayer.Multiplayer
end

function GTetris.SyncCurrentPiece(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
end

--[[
	x
	y
	rotation
	piece id
]]
function GTetris.SyncPieceStates(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local origin = localplayer.CurrentPosition
	net.Start("GTetris.SyncPieceState")
	net.WriteInt(origin.x, 7)
	net.WriteInt(origin.y, 7)
	net.WriteInt(localplayer.CurrentRotationState, 5)
	net.WriteInt(localplayer.CurrentPiece, 5)
	net.WriteInt(localplayer.CurrentHoldPiece, 5)
	net.SendToServer()
end

function GTetris.SyncBoard(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local data, length = GTetris.CompressTable(localplayer.CurrentBoard)
	net.Start("GTetris.SyncBoard")
	net.WriteUInt(length, 32)
	net.WriteData(data, length)
	net.SendToServer()
end

function GTetris.SyncNextPieces(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	
end

local lastsdTime1 = 0
function GTetris.SendMoveSound(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	
end

local lastsdTime2 = 0
function GTetris.SendSoftdropSound(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	
end

function GTetris.SendClearSound(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	
end

function GTetris.SyncDeadStatus(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	
end

net.Receive("GTetris.SyncRuletset", function(length, sender)
	local length = net.ReadUInt(32)
	local data = net.ReadData(length)
	local rulesets = GTetris.DecompressTable(data)
	GTetris.ApplyRulesets(rulesets)
end)

net.Receive("GTetris.SyncRoomData", function(length, sender)
	local length = net.ReadUInt(32)
	local data = net.ReadData(length)
	local roomData = GTetris.DecompressTable(data)
	GTetris.RoomData = roomData
	if(IsValid(GTetris.CurrentPlayerList)) then
		GTetris.CurrentPlayerList.ReloadPlayers()
	end
end)

net.Receive("GTetris.Respond", function(length, sender)
	GTetris.RespondWaiting()
end)

net.Receive("GTetris.SyncBoard", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		local boardData = GTetris.DecompressTable(data)
		board.CurrentBoard = boardData
	end
end)

net.Receive("GTetris.SyncPieceState", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local rotation = net.ReadInt(5)
	local piece = net.ReadInt(5)
	local holdpiece = net.ReadInt(5)
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		board.CurrentPosition = {
			x = x,
			y = y,
		}
		board.CurrentRotationState = rotation
		board.CurrentPiece = piece
		board.CurrentHoldPiece = holdpiece
	end
end)