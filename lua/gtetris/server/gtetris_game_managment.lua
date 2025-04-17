util.AddNetworkString("GTetris.Respond")
util.AddNetworkString("GTetris.StartGame")
util.AddNetworkString("GTetris.InitBoardLayer")
util.AddNetworkString("GTetris.PlayerQuitedRoom")
util.AddNetworkString("GTetris.SyncPieceState")
util.AddNetworkString("GTetris.SyncBoard")

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
			continue
		end
		table.insert(boardData.players, {
			playerID = player:GetCreationID(),
			nick = player:Nick(),
		})
		table.insert(GTetris.RoomsState[rID].datasync_targets, player)
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

net.Receive("GTetris.SyncBoard", function(length, sender)
	local rID = sender.GTetrisRoomID
	if(!GTetris.IsPlayerInRoom(sender)) then
		return
	end
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
end)