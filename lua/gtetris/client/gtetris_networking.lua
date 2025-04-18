function GTetris.IsInMultiplayerGame()
	return IsValid(GTetris.BoardLayer) && GTetris.BoardLayer.Multiplayer
end

function GTetris.SyncBoardInfo(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	net.Start("GTetris.SyncBoardInfo")
	net.WriteInt(localplayer.CurrentB2B, 10)
	net.WriteInt(localplayer.CurrentCombo, 10)
	net.SendToServer()
end

function GTetris.SyncReceivedAttacks(localplayer)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local attacks = localplayer.ReceivedAttacks
	local data, length = GTetris.CompressTable(attacks)
	net.Start("GTetris.SyncReceivedAttacks")
	net.WriteUInt(length, 32)
	net.WriteData(data, length)
	net.SendToServer()
end

function GTetris.SendAllClear()
	if(!GTetris.IsInMultiplayerGame()) then return end
	net.Start("GTetris.SendAllClear")
	net.SendToServer()
end

function GTetris.SendDeathAnimation()
	net.Start("GTetris.SyncDeathState")
	net.SendToServer()
end

function GTetris.SendAttacks(attacks, x, y)
	if(!GTetris.IsInMultiplayerGame()) then return end
	net.Start("GTetris.SendAttack")
	net.WriteInt(x, 7)
	net.WriteInt(y, 7)
	net.WriteInt(attacks, 32)
	net.SendToServer()

	local localplayer = GTetris.GetLocalPlayer()
	if(!IsValid(localplayer)) then return end
	local targetboard = GTetris.GetBoard(localplayer.AttackingBoardID)
	if(!IsValid(targetboard)) then return end
	local layer = GTetris.BoardLayer
	local blocksize = layer.BoardBlockSize
	local from, to
	local scalea, scaleb = localplayer.CurrentScale, targetboard.CurrentScale
	from = {x = (localplayer.CurrentXOffset || 0) + (x * (blocksize * scalea)), y = (localplayer.CurrentYOffset || 0) + (y * (blocksize * scalea))}
	to = {x = (targetboard.CurrentXOffset || 0) + ((targetboard:GetWide() * 0.5) * scaleb), y = (targetboard.CurrentYOffset || 0) + ((targetboard:GetTall() * 0.5) * scaleb)}
	if(!from || !to) then return end
	layer.InsertAttackTrace(from, to)
end

function GTetris.SendClearLineInfo(piece, lines, spinBonus, combo, attackBonus)
	if(!GTetris.IsInMultiplayerGame()) then return end
	net.Start("GTetris.LineCleared")
	net.WriteInt(piece, 5)
	net.WriteInt(lines, 5)
	net.WriteBool(spinBonus)
	net.WriteInt(combo, 10)
	net.WriteBool(attackBonus)
	net.SendToServer()
end

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
	local pieces = ""
	for _, piece in ipairs(localplayer.CurrentPieces) do
		pieces = pieces..piece
	end
	net.Start("GTetris.SyncNextPieces")
	net.WriteString(pieces)
	net.SendToServer()
end

function GTetris.SendBoardTexts(x, y, num, cancel)
	if(!GTetris.IsInMultiplayerGame()) then return end
	net.Start("GTetris.SendBoardText")
	net.WriteInt(x, 7)
	net.WriteInt(y, 7)
	net.WriteInt(num, 32)
	net.WriteBool(cancel)
	net.SendToServer()
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

net.Receive("GTetris.SyncNextPieces", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local pieces = net.ReadString()
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		board.CurrentPieces = {}
		for i = 1, #pieces do
			table.insert(board.CurrentPieces, tonumber(pieces[i]))
		end
	end
end)

net.Receive("GTetris.SendBoardText", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local num = net.ReadInt(32)
	local cancel = net.ReadBool()
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		GTetris.AddBoardText(board, x, y, num, cancel)
	end
end)

net.Receive("GTetris.SyncBoardInfo", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local b2b = net.ReadInt(10)
	local combo = net.ReadInt(10)
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		board.CurrentB2B = b2b
		board.CurrentCombo = combo
	end
end)

net.Receive("GTetris.LineCleared", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local piece = net.ReadInt(5)
	local lines = net.ReadInt(5)
	local spinBonus = net.ReadBool()
	local combo = net.ReadInt(10)
	local attackBonus = net.ReadBool()
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		GTetris.SetClearText(boardID, lines)
		if(spinBonus) then
			GTetris.SetSpinText(boardID, piece)
		end
	end
end)

net.Receive("GTetris.SendAllClear", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		GTetris.InsertAllClears(boardID)
		local layer = GTetris.BoardLayer
		if(layer.Amount <= 4) then
			if(board == layer.FocusingBoard) then
				GTetris.AllClearSound(2)
			else
				GTetris.AllClearSound(1)
			end
		end
	end
end)

net.Receive("GTetris.SendAttack", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local attackerID = net.ReadString()
	local victimID = net.ReadString()
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local attacks = net.ReadInt(32)
	local attacker_board = GTetris.GetBoard(attackerID)
	local victim_board = GTetris.GetBoard(victimID)
	if(IsValid(attacker_board) && IsValid(victim_board)) then
		if(victim_board == GTetris.GetLocalPlayer()) then
			timer.Simple(GTetris.Rulesets.AttackArriveTime, function()
				GTetris.ReceiveAttack(attacks)
				GTetris.SyncReceivedAttacks(GTetris.GetLocalPlayer())
			end)
		end

		local layer = GTetris.BoardLayer
		local blocksize = layer.BoardBlockSize
		local from, to
		local scalea, scaleb = attacker_board.CurrentScale, victim_board.CurrentScale
		from = {x = (attacker_board.CurrentXOffset || 0) + (x * (blocksize * scalea)), y = (attacker_board.CurrentYOffset || 0) + (y * (blocksize * scalea))}
		to = {x = (victim_board.CurrentXOffset || 0) + ((victim_board:GetWide() * 0.5) * scaleb), y = (victim_board.CurrentYOffset || 0) + ((victim_board:GetTall() * 0.5) * scaleb)}

		if(!from || !to) then return end
		layer.InsertAttackTrace(from, to)
	end
end)

net.Receive("GTetris.SyncTargets", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local layer = GTetris.BoardLayer
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local targets = GTetris.DecompressTable(data)
	local beingtargetted = 0
	for attackerID, victimID in pairs(targets) do
		attackerID = tostring(attackerID)
		victimID = tostring(victimID)
		local attacker_board = GTetris.GetBoard(attackerID)
		if(IsValid(attacker_board) && attacker_board.Alive) then
			attacker_board.AttackingBoardID = victimID
			if(GTetris.GetBoard(victimID) == layer.FocusingBoard) then
				beingtargetted = beingtargetted + 1
			end
		end
	end

	if(IsValid(GTetris.GetBoard(victimID))) then
		GTetris.GetBoard(victimID).BeingTargetted = beingtargetted
	end
end)

net.Receive("GTetris.SyncReceivedAttacks", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	local attacks = GTetris.DecompressTable(data)
	if(IsValid(GTetris.GetBoard(boardID))) then
		GTetris.GetBoard(boardID).ReceivedAttacks = attacks
	end
end)

net.Receive("GTetris.SyncDeathState", function(length, sender)
	if(!GTetris.IsInMultiplayerGame()) then return end
	local boardID = net.ReadString()
	local board = GTetris.GetBoard(boardID)
	if(IsValid(board)) then
		board.StartDeathAnimation()
	end
end)