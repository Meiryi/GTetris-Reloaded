GTetris.Input_DAS = 0.115
GTetris.Input_ARR = 0
GTetris.Input_SDF = 50

local keyStates = {}
local currentDAS = 0
local currentARR = 0
local currentSDF = 0
local dasKeys = {
	Left = true,
	Right = true,
}
local oneShotKeys = {
	RotateLeft = true,
	RotateRight = true,
	Rotate180 = true,
	Hold = true,
	Drop = true,
}

function GTetris.Left(localplayer)
	if(GTetris.MovePiece(localplayer, -1, 0)) then
		GTetris.PieceMoved(localplayer)
	end
end

function GTetris.Right(localplayer)
	if(GTetris.MovePiece(localplayer, 1, 0)) then
		GTetris.PieceMoved(localplayer)
	end
end

function GTetris.Drop(localplayer)
	GTetris.PlacePiece(localplayer)
end

function GTetris.PieceRotated(localplayer)
	GTetris.RotateSound(localplayer.Bonus, 4)
	GTetris.SyncPieceStates(localplayer)
end

function GTetris.PieceMoved(localplayer, nosound)
	if(!nosound) then
		GTetris.MoveSound(4)
	end
	GTetris.SyncPieceStates(localplayer)
end

function GTetris.PieceSoftdrop(localplayer)
	
end

function GTetris.RotateLeft(localplayer)
	local origin = localplayer.CurrentPosition
	local CurrentState = localplayer.CurrentRotationState
	local WishState = CurrentState + -1
	if(WishState < 1) then
		WishState = 4
	end
	if(GTetris.ProcessRotation(
		localplayer.CurrentBoard,
		localplayer.CurrentPiece,localplayer.RotationRule,
		GTetris.Blocks[localplayer.CurrentPiece][WishState],
		origin.x,
		origin.y,
		CurrentState,
		WishState,
		localplayer
	)) then
		localplayer.CurrentRotationState = WishState
		localplayer.Bonus = GTetris.CheckBonus(localplayer.CurrentBoard, GTetris.Blocks[localplayer.CurrentPiece][WishState], localplayer.CurrentPosition)
		GTetris.PieceRotated(localplayer)
	end
end

function GTetris.RotateRight(localplayer)
	local origin = localplayer.CurrentPosition
	local CurrentState = localplayer.CurrentRotationState
	local WishState = CurrentState + 1
	if(WishState > 4) then
		WishState = 1
	end
	local newShape = GTetris.Blocks[localplayer.CurrentPiece][WishState]
	if(GTetris.ProcessRotation(
		localplayer.CurrentBoard,
		localplayer.CurrentPiece,localplayer.RotationRule,
		GTetris.Blocks[localplayer.CurrentPiece][WishState],
		origin.x,
		origin.y,
		CurrentState,
		WishState,
		localplayer
	)) then
		localplayer.CurrentRotationState = WishState
		localplayer.Bonus = GTetris.CheckBonus(localplayer.CurrentBoard, GTetris.Blocks[localplayer.CurrentPiece][WishState], localplayer.CurrentPosition)
		GTetris.PieceRotated(localplayer)
	end
end

function GTetris.Rotate180(localplayer)
	local origin = localplayer.CurrentPosition
	local CurrentState = localplayer.CurrentRotationState
	local WishState = CurrentState + 2
	if(WishState > 4) then
		WishState = WishState - 4
	end
	if(WishState < 1) then
		WishState = WishState + 4
	end
	local newShape = GTetris.Blocks[localplayer.CurrentPiece][WishState]
	if(GTetris.ProcessRotation(
		localplayer.CurrentBoard,
		localplayer.CurrentPiece,localplayer.RotationRule,
		GTetris.Blocks[localplayer.CurrentPiece][WishState],
		origin.x,
		origin.y,
		CurrentState,
		WishState,
		localplayer
	)) then
		localplayer.CurrentRotationState = WishState
		localplayer.Bonus = GTetris.CheckBonus(localplayer.CurrentBoard, GTetris.Blocks[localplayer.CurrentPiece][WishState], localplayer.CurrentPosition)
		GTetris.PieceRotated(localplayer)
	end
end

function GTetris.Hold(localplayer)
	if(localplayer.HoldUsed) then return end
	if(localplayer.CurrentHoldPiece != -1) then
		local oldFirstPiece = localplayer.CurrentPiece
		local newFirstPiece = localplayer.CurrentHoldPiece
		localplayer.CurrentHoldPiece = oldFirstPiece
		localplayer.CurrentPiece = newFirstPiece
	else
		localplayer.CurrentHoldPiece = localplayer.CurrentPiece
		table.remove(localplayer.CurrentPieces, 1)
		localplayer.CurrentPiece = localplayer.CurrentPieces[1]
		if(#localplayer.CurrentPieces <= 6) then
			local newPieces = GTetris.GeneratePieces(GTetris.Rulesets.BagSystem, localplayer.CurrentSeed)
			table.Add(localplayer.CurrentPieces, newPieces)
			localplayer.CurrentSeed = localplayer.CurrentSeed + 1
		end
	end
	localplayer.CurrentPosition.x = math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[localplayer.CurrentPiece]) / 2)
	localplayer.CurrentPosition.y = -2
	localplayer.CurrentRotationState = 4
	localplayer.HoldUsed = true
	GTetris.HoldSound(4)
	GTetris.PieceResetted(localplayer)
	GTetris.SyncPieceStates(localplayer)
	GTetris.SyncNextPieces(localplayer)
end

function GTetris.Softdrop(localplayer)
	if(GTetris.MovePiece(localplayer, 0, 1)) then
		GTetris.SoftDropSound(4)
		GTetris.SyncPieceStates(localplayer)
	end
end

hook.Add("Think", "GTetris_InputHandler", function()
	local localplayer = GTetris.GetLocalPlayer()
	if(!IsValid(localplayer) || !localplayer.Alive || !localplayer.InputEnabled) then return end
	local systime = SysTime()
	for key, _ in pairs(dasKeys) do
		local keycode = GTetris.Keys[key]
		if(input.IsKeyDown(keycode)) then
			if(!keyStates[key]) then
				keyStates[key] = true
				GTetris[key](localplayer)
				currentDAS = systime + GTetris.Input_DAS
			end
			if(currentDAS < systime && currentARR < systime) then
				if(GTetris.Input_ARR <= 0) then
					for i = 1, GTetris.Rulesets.Width do
						GTetris[key](localplayer)
					end
				else
					GTetris[key](localplayer)
				end
				currentARR = systime + GTetris.Input_ARR
			end
		else
			if(keyStates[key]) then
				keyStates[key] = false
			end
		end
	end
	for key, _ in pairs(oneShotKeys) do
		local keycode = GTetris.Keys[key]
		if(input.IsKeyDown(keycode)) then
			if(!keyStates[key]) then
				GTetris[key](localplayer)
				keyStates[key] = true
			end
		else
			if(keyStates[key]) then
				keyStates[key] = false
			end
		end
	end
	if(input.IsKeyDown(GTetris.Keys.Softdrop)) then
		if(currentSDF < systime) then
			if(GTetris.Input_SDF >= 50) then
				for i = 1, GTetris.Rulesets.Height do
					GTetris.Softdrop(localplayer)
				end
			else
				GTetris.Softdrop(localplayer)
			end
			currentSDF = systime + (1 / GTetris.Input_SDF)
		end
	end
end)