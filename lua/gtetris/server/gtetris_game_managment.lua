util.AddNetworkString("GTetris.Respond")
util.AddNetworkString("GTetris.StartGame")
util.AddNetworkString("GTetris.InitBoardLayer")
util.AddNetworkString("GTetris.PlayerQuitedRoom")
util.AddNetworkString("GTetris.SyncPieceState")
util.AddNetworkString("GTetris.SyncBoard")
util.AddNetworkString("GTetris.SyncNextPieces")
util.AddNetworkString("GTetris.SendBoardText")
util.AddNetworkString("GTetris.SyncBoardInfo")
util.AddNetworkString("GTetris.LineCleared")
util.AddNetworkString("GTetris.SendAllClear")
util.AddNetworkString("GTetris.SendAttack")
util.AddNetworkString("GTetris.SyncTargets")
util.AddNetworkString("GTetris.SyncReceivedAttacks")
util.AddNetworkString("GTetris.SyncDeathState")
util.AddNetworkString("GTetris.EndGame")

function GTetris.RespondPlayer(ply)
	net.Start("GTetris.Respond")
	net.Send(ply)
end

function GTetris.SendNotify(ply, title, desc)
	net.Start("GTetris.Notify")
	net.WriteString(title)
	net.WriteString(desc)
	net.Send(ply)
end

function GTetris.AddSpectator(ply)

end

function GTetris.EndGame(rID, winnerNick)
	if(!GTetris.RoomsState[rID]) then return end
	local roomdata = GTetris.Rooms[rID]
	for _, player in pairs(roomdata.players) do
		if(istable(player)) then continue end -- bot
		net.Start("GTetris.EndGame")
		net.Send(player)
	end
	GTetris.RoomsState[rID] = nil
	GTetris.RoomsTargets[rID] = nil
end

net.Receive("GTetris.StartGame", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender) || !GTetris.IsRoomHost(sender)) then
		GTetris.SendNotify(sender, "Failed to start the game", "You are not the host of this room.")
		return
	end
	local roomdata = GTetris.Rooms[rID]
	if(GTetris.RoomsState[rID]) then -- Game is already started
		--return
	end
	GTetris.RoomsState[rID] = {
		aliveplayers = {},
		datasync_targets = {},
	}
	GTetris.RoomsTargets[rID] = {}
	local boardData = {
		ruleset = roomdata.ruleset,
		players = {},
	}
	for _, player in pairs(roomdata.players) do
		if(istable(player)) then -- bot
			table.insert(boardData.players, {
				bot = true,
				playerID = player.BotID,
				nick = player.BotName,
			})
			GTetris.RoomsTargets[rID][player.BotID] = "null"
			GTetris.RoomsState[rID].aliveplayers[player.BotID] = {
				nick = player.BotName,
				alive = true,
				bot = true,
			}
			continue
		end
		table.insert(boardData.players, {
			playerID = player:GetCreationID(),
			nick = player:Nick(),
		})
		table.insert(GTetris.RoomsState[rID].datasync_targets, player)
		GTetris.RoomsTargets[rID][player:GetCreationID()] = "null"
		GTetris.RoomsState[rID].aliveplayers[player:GetCreationID()] = {
			nick = player:Nick(),
			alive = true,
			bot = false,
			entity = player,
		}
	end

	local data, len = GTetris.CompressTable(boardData)
	for _, player in pairs(roomdata.players) do
		if(istable(player)) then continue end -- bot
		net.Start("GTetris.InitBoardLayer")
		net.WriteUInt(len, 32)
		net.WriteData(data, len)
		net.Send(player)
	end
end)

net.Receive("GTetris.SyncPieceState", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local rotation = net.ReadInt(5)
	local pieceid = net.ReadInt(5)
	local holdpieceid = net.ReadInt(5)
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncPieceState")
		net.WriteString(targetid)
		net.WriteInt(x, 7)
		net.WriteInt(y, 7)
		net.WriteInt(rotation, 5)
		net.WriteInt(pieceid, 5)
		net.WriteInt(holdpieceid, 5)
		net.Send(ply)
	end
end)

function GTetris.SyncBoard(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncBoard")
		net.WriteString(targetid)
		net.WriteUInt(len, 32)
		net.WriteData(data, len)
		net.Send(ply)
	end
end

net.Receive("GTetris.SyncBoard", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SyncBoard(sender, rID)
end)

function GTetris.SyncNextPieces(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local pieces = net.ReadString()
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncNextPieces")
		net.WriteString(targetid)
		net.WriteString(pieces)
		net.Send(ply)
	end
end

net.Receive("GTetris.SyncNextPieces", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SyncNextPieces(sender, rID)
end)

function GTetris.SendBoardText(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local num = net.ReadInt(32)
	local cancel = net.ReadBool()
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SendBoardText")
		net.WriteString(targetid)
		net.WriteInt(x, 7)
		net.WriteInt(y, 7)
		net.WriteInt(num, 32)
		net.WriteBool(cancel)
		net.Send(ply)
	end
end

net.Receive("GTetris.SendBoardText", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SendBoardText(sender, rID)
end)

function GTetris.SyncBoardInfo(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local b2b = net.ReadInt(10)
	local combo = net.ReadInt(10)
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncBoardInfo")
		net.WriteString(targetid)
		net.WriteInt(b2b, 10)
		net.WriteInt(combo, 10)
		net.Send(ply)
	end
end

net.Receive("GTetris.SyncBoardInfo", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SyncBoardInfo(sender, rID)
end)

function GTetris.LineCleared(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local piece = net.ReadInt(5)
	local lines = net.ReadInt(5)
	local spin = net.ReadBool()
	local combo = net.ReadInt(10)
	local attackbonus = net.ReadBool()
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.LineCleared")
		net.WriteString(targetid)
		net.WriteInt(piece, 5)
		net.WriteInt(lines, 5)
		net.WriteBool(spin)
		net.WriteInt(combo, 10)
		net.WriteBool(attackbonus)
		net.Send(ply)
	end
end

net.Receive("GTetris.LineCleared", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.LineCleared(sender, rID)
end)

function GTetris.SendAllClear(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SendAllClear")
		net.WriteString(targetid)
		net.Send(ply)
	end
end

net.Receive("GTetris.SendAllClear", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SendAllClear(sender, rID)
end)

function GTetris.SendAttack(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local target = (GTetris.RoomsTargets[rID] || {})[targetid]
	local x = net.ReadInt(7)
	local y = net.ReadInt(7)
	local lines = net.ReadInt(32)
	if(!target) then
		return
	end
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SendAttack")
		net.WriteString(targetid)
		net.WriteString(target)
		net.WriteInt(x, 7)
		net.WriteInt(y, 7)
		net.WriteInt(lines, 32)
		net.Send(ply)
	end
end

net.Receive("GTetris.SendAttack", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SendAttack(sender, rID)
end)

function GTetris.SyncReceivedAttacks(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local len = net.ReadUInt(32)
	local data = net.ReadData(len)
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncReceivedAttacks")
		net.WriteString(targetid)
		net.WriteUInt(len, 32)
		net.WriteData(data, len)
		net.Send(ply)
	end
end

net.Receive("GTetris.SyncReceivedAttacks", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SyncReceivedAttacks(sender, rID)
end)

function GTetris.SyncDeathState(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	GTetris.RoomsState[rID].aliveplayers[sender:GetCreationID()].alive = false
	local targetid = sender:GetCreationID()
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SyncDeathState")
		net.WriteString(targetid)
		net.Send(ply)
	end
	GTetris.RandPlayerTargets(rID)

	local aliveplayers = 0
	local winnerNick = ""
	for _, player in pairs(GTetris.RoomsState[rID].aliveplayers) do
		if(!player.bot && !IsValid(player.entity)) then continue end
		if(player.alive) then
			aliveplayers = aliveplayers + 1
			winnerNick = player.nick || "null"
		end
	end

	if(aliveplayers <= 1) then
		GTetris.EndGame(rID, winnerNick)
	end
end

net.Receive("GTetris.SyncDeathState", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SyncDeathState(sender, rID)
end)

function GTetris.RandPlayerTargets(roomID)
	if(!GTetris.RoomsState[roomID]) then return end
		local players = GTetris.RoomsTargets[roomID]
		local sortedplayers = {}
		for playerid, ply in pairs(players) do
			table.insert(sortedplayers, {
				playerid = playerid,
			})
		end
		local plycount = #sortedplayers
		if(plycount == 2) then
			GTetris.RoomsTargets[roomID][sortedplayers[1].playerid] = sortedplayers[2].playerid
			GTetris.RoomsTargets[roomID][sortedplayers[2].playerid] = sortedplayers[1].playerid
		elseif(plycount > 2) then
			for playerid, _ in pairs(GTetris.RoomsTargets[roomID]) do
				local newlist = {}
				for plyid, _ in pairs(GTetris.RoomsTargets[roomID]) do
					if(plyid == playerid) then continue end
					table.insert(newlist, plyid)
				end
				local randomply = table.Random(newlist)
				if(randomply) then
					GTetris.RoomsTargets[roomID][playerid] = randomply
				else
					GTetris.RoomsTargets[roomID][playerid] = "null"
				end
			end
		end
		local data, len = GTetris.CompressTable(GTetris.RoomsTargets[roomID])
		for _, player in pairs(GTetris.RoomsState[roomID].datasync_targets) do
			if(!IsValid(player)) then continue end
			net.Start("GTetris.SyncTargets")
			net.WriteUInt(len, 32)
			net.WriteData(data, len)
			net.Send(player)
		end
end

local nextExecute = 0
hook.Add("Think", "GTetris_TargetRandomize", function()
	if(nextExecute > SysTime()) then return end
	for roomid, players in pairs(GTetris.RoomsTargets) do
		GTetris.RandPlayerTargets(roomid)
	end
	nextExecute = SysTime() + 5
end)