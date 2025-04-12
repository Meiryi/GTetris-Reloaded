GTetris.Input_DAS = 0.167
GTetris.Input_ARR = 0.033
GTetris.Input_SDF = 10

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
	GTetris.MovePiece(localplayer, -1, 0)
end

function GTetris.Right(localplayer)
	GTetris.MovePiece(localplayer, 1, 0)
end

function GTetris.Drop(localplayer)
	GTetris.PlacePiece(localplayer)
end

function GTetris.RotateLeft(localplayer)
	local origin = localplayer.CurrentPosition
	local CurrentState = localplayer.CurrentRotationState
	local WishState = CurrentState + 1
	if(WishState > 4) then
		WishState = 1
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
	end
end

function GTetris.RotateRight(localplayer)
	local origin = localplayer.CurrentPosition
	local CurrentState = localplayer.CurrentRotationState
	local WishState = CurrentState - 1
	if(WishState < 1) then
		WishState = 4
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
	end
end

function GTetris.Hold(localplayer)

end

function GTetris.Softdrop(localplayer)
	GTetris.MovePiece(localplayer, 0, 1)
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
				if(currentDAS < systime) then
					GTetris[key](localplayer)
					currentDAS = systime + GTetris.Input_DAS
				end
			end
			if(currentDAS < systime && currentARR < systime) then
				GTetris[key](localplayer)
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
			GTetris.Softdrop(localplayer)
			currentSDF = systime + (1 / GTetris.Input_SDF)
		end
	end
end)