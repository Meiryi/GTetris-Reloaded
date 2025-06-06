GTetris.PlayerDatas = GTetris.PlayerDatas || {}

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
util.AddNetworkString("GTetris.SpectateGame")
util.AddNetworkString("GTetris.AbortGame")
util.AddNetworkString("GTetris.SendSound")

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

net.Receive("GTetris.SpectateGame", function(length, sender)
	local rID = sender.GTetrisRoomID
	local roomdata = GTetris.Rooms[rID]
	local state = GTetris.RoomsState[rID]
	if(!roomdata) then
		GTetris.SendNotify(sender, "Failed to spectate the game", "This room does not exist.")
		return
	end
	if(!state) then
		GTetris.SendNotify(sender, "Failed to spectate the game", "This game has ended.")
		return
	end
	if(!GTetris.IsPlayerInRoom(sender)) then
		GTetris.SendNotify(sender, "Failed to spectate the game", "You are not in this room.")
		return
	end
	--[[
	GTetris.RoomStartedTimes[rID] = SysTime() + 4
	GTetris.RoomsState[rID] = {
		aliveplayers = {},
		datasync_targets = {},
	}
	GTetris.RoomsTargets[rID] = {}
	local boardData = {
		ruleset = roomdata.ruleset,
		roomName = roomdata.roomname,
		players = {},
	}
	GTetris.Rooms[rID].started = true
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
		net.WriteBool(true)
		net.Send(player)
	end

		x
		y
		rotation
		pieceid
		holdpieceid
		board
		nextpieces
		b2b
		combo
		receivedattacks
	]]
	local aliveplayers = GTetris.RoomsState[rID].aliveplayers
	local boardData = {
		ruleset = roomdata.ruleset,
		roomName = roomdata.roomname,
		players = {},
	}
	for id, player in pairs(aliveplayers) do
		if(!player.alive) then
			continue
		end
		if(player.bot) then
			table.insert(boardData.players, {
				bot = true,
				playerID = id,
				nick = player.nick,
			})
		else
			if(!IsValid(player.entity)) then
				continue
			end
			table.insert(boardData.players, {
				playerID = player.entity:GetCreationID(),
				nick = player.nick,
			})
		end
	end

	local playerData = GTetris.PlayerDatas[rID] || {}

	local data, len = GTetris.CompressTable(boardData)
	local data2, len2 = GTetris.CompressTable(playerData)
	net.Start("GTetris.InitBoardLayer")
	net.WriteUInt(len, 32)
	net.WriteData(data, len)
	net.WriteBool(true)
	net.WriteBool(true)
	net.WriteUInt(len2, 32)
	net.WriteData(data2, len2)
	net.Send(sender)

	table.insert(GTetris.RoomsState[rID].datasync_targets, sender)
end)

function GTetris.EndGame(rID, winnerNick)
	if(!GTetris.RoomsState[rID]) then return end
	local roomdata = GTetris.Rooms[rID]
	for _, player in pairs(roomdata.players) do
		if(istable(player)) then continue end -- bot
		net.Start("GTetris.EndGame")
		net.WriteString(winnerNick)
		net.Send(player)
	end
	GTetris.RoomsState[rID] = nil
	GTetris.RoomsTargets[rID] = nil
	GTetris.Rooms[rID].started = false
	GTetris.PlayerDatas[rID] = {}
	GTetris.SyncRoomDatas(rID)
end

net.Receive("GTetris.StartGame", function(length, sender)
	local rID = sender.GTetrisRoomID
	local roomdata = GTetris.Rooms[rID]
	if(!GTetris.IsPlayerInRoom(sender) || !GTetris.IsRoomHost(sender)) then
		GTetris.SendNotify(sender, "Failed to start the game", "You are not the host of this room.")
		return
	end
	if(table.Count(roomdata.players) <= 1) then
		GTetris.SendNotify(sender, "Failed to start the game", "You need at least 2 players to start the game.")
		return
	end
	if(GTetris.RoomsState[rID]) then
		return
	end
	if(GTetris.RoomStartedTimes[rID] && GTetris.RoomStartedTimes[rID] > SysTime()) then
		GTetris.SendNotify(sender, "Failed to start the game", "Please wait a bit before starting the game. ("..math.floor(GTetris.RoomStartedTimes[rID] - SysTime()).."s)")
		return
	end
	GTetris.RoomStartedTimes[rID] = SysTime() + 4
	GTetris.RoomsState[rID] = {
		aliveplayers = {},
		datasync_targets = {},
	}
	GTetris.RoomsTargets[rID] = {}
	local boardData = {
		ruleset = table.Copy(roomdata.ruleset),
		roomName = roomdata.roomname,
		players = {},
	}
	boardData.ruleset.Seed = math.random(0, 32767)
	GTetris.Rooms[rID].started = true
	GTetris.PlayerDatas[rID] = {}
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
		net.WriteBool(false)
		net.WriteBool(false)
		net.Send(player)
	end
	GTetris.SyncRoomDatas(rID)
	GTetris.RandPlayerTargets(rID)
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
	if(GTetris.PlayerDatas[rID]) then
		if(!GTetris.PlayerDatas[rID][sender:GetCreationID()]) then
			GTetris.PlayerDatas[rID][sender:GetCreationID()] = {}
		end
		GTetris.PlayerDatas[rID][sender:GetCreationID()].x = x
		GTetris.PlayerDatas[rID][sender:GetCreationID()].y = y
		GTetris.PlayerDatas[rID][sender:GetCreationID()].rotation = rotation
		GTetris.PlayerDatas[rID][sender:GetCreationID()].pieceid = pieceid
		GTetris.PlayerDatas[rID][sender:GetCreationID()].holdpieceid = holdpieceid
	end
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
	if(GTetris.PlayerDatas[rID]) then
		if(!GTetris.PlayerDatas[rID][sender:GetCreationID()]) then
			GTetris.PlayerDatas[rID][sender:GetCreationID()] = {}
		end
		GTetris.PlayerDatas[rID][sender:GetCreationID()].board = data
	end
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
	if(GTetris.PlayerDatas[rID]) then
		if(!GTetris.PlayerDatas[rID][sender:GetCreationID()]) then
			GTetris.PlayerDatas[rID][sender:GetCreationID()] = {}
		end
		GTetris.PlayerDatas[rID][sender:GetCreationID()].nextpieces = pieces
	end
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
	if(GTetris.PlayerDatas[rID]) then
		if(!GTetris.PlayerDatas[rID][sender:GetCreationID()]) then
			GTetris.PlayerDatas[rID][sender:GetCreationID()] = {}
		end
		GTetris.PlayerDatas[rID][sender:GetCreationID()].b2b = b2b
		GTetris.PlayerDatas[rID][sender:GetCreationID()].combo = combo
	end
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
	if(GTetris.PlayerDatas[rID]) then
		if(!GTetris.PlayerDatas[rID][sender:GetCreationID()]) then
			GTetris.PlayerDatas[rID][sender:GetCreationID()] = {}
		end
		GTetris.PlayerDatas[rID][sender:GetCreationID()].receivedattacks = data
	end

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

function GTetris.RemoveDataSync(rID, player)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	for _, ply in pairs(targets) do
		if(ply == player) then
			table.remove(targets, _)
			break
		end
	end
end

net.Receive("GTetris.AbortGame", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.RemoveDataSync(rID, sender)
	GTetris.SyncDeathState(sender, sender:GetCreationID(), rID)

	if(sender:GetCreationID() == GTetris.Rooms[rID].host) then
		GTetris.RoomStartedTimes[rID] = SysTime() + 4
	end
end)

function GTetris.SyncDeathState(sender, cID, rID)
	if(!GTetris.RoomsState[rID] ||!GTetris.RoomsState[rID].aliveplayers[cID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	GTetris.RoomsState[rID].aliveplayers[cID].alive = false
	GTetris.RoomsTargets[rID][cID] = nil
	local targetid = cID
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
	GTetris.SyncDeathState(sender, sender:GetCreationID(), rID)
end)

function GTetris.SendSound(sender, rID)
	if(!GTetris.RoomsState[rID]) then return end
	local targets = GTetris.RoomsState[rID].datasync_targets
	local targetid = sender:GetCreationID()
	local type = net.ReadInt(6)
	for _, ply in pairs(targets) do
		if(!IsValid(ply) || ply == sender) then continue end
		net.Start("GTetris.SendSound")
		net.WriteString(targetid)
		net.WriteInt(type, 6)
		net.Send(ply)
	end
end

net.Receive("GTetris.SendSound", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
	GTetris.SendSound(sender, rID)
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