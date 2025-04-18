GTetris.Rooms = GTetris.Rooms || {}
GTetris.RoomsState = {}
GTetris.RoomsTargets = {}

util.AddNetworkString("GTetris.CreateRoom")
util.AddNetworkString("GTetris.JoinRoom")
util.AddNetworkString("GTetris.LeaveRoom")
util.AddNetworkString("GTetris.SyncRuletset")
util.AddNetworkString("GTetris.SyncRoomData")
util.AddNetworkString("GTetris.GetRooms")
util.AddNetworkString("GTetris.Notify")
util.AddNetworkString("GTetris.Chat")
util.AddNetworkString("GTetris.ModifyVars")

function GTetris.CreateRoom(rID, host)
	GTetris.Rooms[rID] = {
		host = host:GetCreationID(),
		roomname = host:Nick().."'s Room",
		players = {
			host,
		},
		spectators = {},
		maxplayers = 4,
		ruleset = table.Copy(GTetris.Rulesets.Default),
	}
	host.GTetrisRoomID = rID
end

function GTetris.IsRoomHost(ply)
	if(!ply.GTetrisRoomID || !GTetris.Rooms[ply.GTetrisRoomID]) then
		return false
	end
	local room = GTetris.Rooms[ply.GTetrisRoomID]
	return room.host == ply:GetCreationID()
end

function GTetris.IsPlayerInRoom(ply)
	if(ply.GTetrisRoomID && GTetris.Rooms[ply.GTetrisRoomID]) then
		return true
	end
	return false
end

function GTetris.SyncRoomDatas(rID, ignore)
	local room = GTetris.Rooms[rID]
	if(!room) then return end
	local roomData = {}
		roomData.host = room.host
		roomData.maxplayers = room.maxplayers
		roomData.players = {}
		roomData.spectators = room.spectators
		roomData.roomname = room.roomname

	for _, ply in pairs(room.players) do
		if(istable(ply)) then -- bot
			table.insert(roomData.players, ply)
			continue
		end
		roomData.players[ply:GetCreationID()] = ply:Nick()
	end

	local data, length = GTetris.CompressTable(roomData)
	for index, ply in pairs(room.players) do
		if(istable(ply) || ply == ignore) then continue end -- bot
		net.Start("GTetris.SyncRoomData")
		net.WriteUInt(length, 32)
		net.WriteData(data, length)
		net.Send(ply)
	end
end

function GTetris.SyncRulesets(rID)
	local room = GTetris.Rooms[rID]
	if(!room) then return end
	local data, length = GTetris.CompressTable(room.ruleset)
	for _, ply in pairs(room.players) do
		if(istable(ply)) then continue end -- bot
		net.Start("GTetris.SyncRuletset")
		net.WriteUInt(length, 32)
		net.WriteData(data, length)
		net.Send(ply)
	end
end

function GTetris.JoinRoom(ply, rID)
	ply.GTetrisRoomID = rID
	table.insert(GTetris.Rooms[rID].players, ply)
	net.Start("GTetris.JoinRoom")
	net.WriteString(rID)
	net.Send(ply)
	GTetris.SyncRulesets(rID)
	GTetris.SyncRoomDatas(rID)
	GTetris.RespondPlayer(ply)
end

function GTetris.LeaveRoom(ply, rID)
	local room = GTetris.Rooms[rID]
	if(GTetris.RoomsState[rID]) then
		GTetris.SyncDeathState(ply, rID);
		((GTetris.RoomsState[rID] || {}).aliveplayers || {})[ply:GetCreationID()] = nil
		((GTetris.RoomsTargets[rID] || {}) || {})[ply:GetCreationID()] = nil
	end

	for _, _ply in pairs(GTetris.Rooms[rID].players) do
		if(_ply == ply) then
			GTetris.Rooms[rID].players[_] = nil
		end
	end

	local playerRemaining = 0
	local players = {}
	ply.GTetrisRoomID = nil
	for _, _ply in pairs(room.players) do
		if(istable(_ply)) then continue end -- bot
		if(_ply != ply) then
			playerRemaining = playerRemaining + 1
			table.insert(players, _ply)
		end
	end

	if(playerRemaining <= 0) then
		GTetris.Rooms[rID] = nil
		GTetris.RoomsState[rID] = nil
		GTetris.RoomsTargets[rID] = nil
		return
	end

	if(ply:GetCreationID() == room.host) then
		local newHost = players[math.random(1, #players)]
		room.host = newHost:GetCreationID()
	end
end

net.Receive("GTetris.LeaveRoom", function(length, sender)
	local roomID = sender.GTetrisRoomID
	local room = GTetris.Rooms[roomID]
	if(!room) then return end
	GTetris.LeaveRoom(sender, roomID)
	GTetris.SyncRoomDatas(roomID)
end)

net.Receive("GTetris.CreateRoom", function(length, sender)
	if(GTetris.IsPlayerInRoom(sender)) then
		print("[GTetris] "..sender:Nick().." tried to create a room while already in one!")
		return
	end
	local rID = GTetris.GetRandomHex(16)
	GTetris.CreateRoom(rID, sender)

	net.Start("GTetris.JoinRoom")
	net.WriteString(rID)
	net.Send(sender)
	GTetris.SyncRulesets(rID)
	GTetris.SyncRoomDatas(rID)
	GTetris.RespondPlayer(sender)
end)

net.Receive("GTetris.JoinRoom", function(length, sender)
	local rID = net.ReadString()
	if(GTetris.IsPlayerInRoom(sender)) then
		print("[GTetris] "..sender:Nick().." tried to join a room while already in one!")
		GTetris.RespondPlayer(sender)
		return
	end
	if(!GTetris.Rooms[rID]) then
		print("[GTetris] "..sender:Nick().." tried to join a room that doesn't exist!")
		GTetris.RespondPlayer(sender)
		GTetris.SendNotify(sender, "Failed to join room", "This room does not exist.")
		return
	end
	GTetris.JoinRoom(sender, rID)
end)

net.Receive("GTetris.GetRooms", function(length, sender)
	local rooms = {}
	for roomid, room in pairs(GTetris.Rooms) do
		local newRoom = {}
		newRoom.name = room.roomname
		newRoom.players = 0
		newRoom.maxplayers = room.maxplayers
		newRoom.roomid = roomid
		for _, _ in pairs(room.players) do
			newRoom.players = newRoom.players + 1
		end
		table.insert(rooms, newRoom)
	end
	local data, length = GTetris.CompressTable(rooms)
	net.Start("GTetris.GetRooms")
	net.WriteUInt(length, 32)
	net.WriteData(data, length)
	net.Send(sender)
end)

net.Receive("GTetris.Chat", function(length, sender)
	local rID = sender.GTetrisRoomID
	local message = net.ReadString()
	if(!rID || !GTetris.Rooms[rID]) then
		print("[GTetris] "..sender:Nick().." tried to send a message while not in a room!")
		return
	end
	for _, ply in pairs(GTetris.Rooms[rID].players) do
		if(istable(ply)) then continue end -- bot
		net.Start("GTetris.Chat")
		net.WriteEntity(sender)
		net.WriteString(message)
		net.Send(ply)
	end
end)

net.Receive("GTetris.SyncRoomData", function(length, sender)
	local roomname = net.ReadString()
	local maxplayers = net.ReadUInt(32)
	if(!GTetris.IsRoomHost(sender)) then
		print("[GTetris] "..sender:Nick().." tried to sync room data while not being the host!")
		return
	end
	local roomID = sender.GTetrisRoomID
	if(!GTetris.Rooms[roomID]) then
		print("[GTetris] "..sender:Nick().." tried to sync room data while not in a room!")
		return
	end
	GTetris.Rooms[roomID].roomname = roomname
	GTetris.Rooms[roomID].maxplayers = maxplayers
	GTetris.SyncRoomDatas(roomID, sender)
	GTetris.RespondPlayer(sender)
end)

net.Receive("GTetris.ModifyVars", function(length, sender)
	local pointer = net.ReadString()
	local type = net.ReadUInt(6)
	if(!GTetris.IsRoomHost(sender)) then
		print("[GTetris] "..sender:Nick().." tried to sync room data while not being the host!")
		return
	end
	local roomID = sender.GTetrisRoomID
	if(!GTetris.Rooms[roomID]) then
		print("[GTetris] "..sender:Nick().." tried to sync room data while not in a room!")
		return
	end
	local value = GTetris.ReadFuncs[type]()
	local svpointer = GTetris.ConvertToServerPointer(pointer)
	GTetris.SetPointerValue(GTetris.Rooms[roomID], svpointer, value)
	--GTetris.SyncRulesets(roomID) -- Do not use this, this is very expensive

	for _, ply in pairs(GTetris.Rooms[roomID].players) do
		if(istable(ply) || ply == sender) then continue end -- bot
		net.Start("GTetris.ModifyVars")
		net.WriteString(pointer)
		net.WriteInt(type, 6)
		GTetris.WriteFuncs[type](value)
		net.Send(ply)
	end
end)

hook.Add("PlayerDisconnected", "GTetris_PlayerDisconnected", function(ply)
	if(GTetris.IsPlayerInRoom(ply)) then
		local roomID = ply.GTetrisRoomID
		GTetris.LeaveRoom(ply, roomID)
		GTetris.SyncRoomDatas(roomID)
	end
end)