function GTetris.AddBoardText(board, x, y, num, cancel)
	if(num <= 0) then return end
	table.insert(board.Numbers, {
		x = x,
		y = y,
		num = num,
		cancel = cancel,
		time = SysTime() + 1,
		alpha = 0,
		scale = 0,
		rotation = math.random(-20, 20),
	})

	if(board == GTetris.GetLocalPlayer()) then
		GTetris.SendBoardTexts(x, y, num, cancel)
	end
end

function GTetris.ReceiveAttack(amount)
	local localplayer = GTetris.GetLocalPlayer()
	if(!IsValid(localplayer)) then return end
	table.insert(localplayer.ReceivedAttacks, {
		amount = amount,
		time = CurTime() + GTetris.Rulesets.AttackApplyDelay,
	})
end

function GTetris.MovePiece(localplayer, x, y)
	local origin = localplayer.CurrentPosition
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	if(GTetris.TestCollision(localplayer.CurrentBoard, shape, origin.x + x, origin.y + y)) then
		localplayer.CurrentPosition.x = origin.x + x
		localplayer.CurrentPosition.y = origin.y + y
		return true
	end
end

function GTetris.TraceToBottom(localplayer)
	local x = localplayer.CurrentPosition.x
	local y = localplayer.CurrentPosition.y
	local bottom = GTetris.Rulesets.Height - 1
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	local board = localplayer.CurrentBoard
	for i = y, bottom do
		if(!GTetris.TestCollision(board, shape, x, i)) then
			return i - 1
		end
	end
end

function GTetris.PlacePiece(localplayer)
	local PlaceX = localplayer.CurrentPosition.x
	local PlaceY = GTetris.TraceToBottom(localplayer)
	local shape = GTetris.Blocks[localplayer.CurrentPiece][localplayer.CurrentRotationState]
	local board = localplayer.CurrentBoard
	for _, block in ipairs(shape) do
		local x = block[1] + PlaceX
		local y = block[2] + PlaceY
		board[y][x] = localplayer.CurrentPiece
	end

	if(#localplayer.CurrentPieces <= 6) then
		local newPieces = GTetris.GeneratePieces(GTetris.Rulesets.BagSystem, localplayer.CurrentSeed)
		table.Add(localplayer.CurrentPieces, newPieces)
		localplayer.CurrentSeed = localplayer.CurrentSeed + 1
	end

	local lineCleared = GTetris.CheckClearLine(board, GTetris.Rulesets.Width - 1, GTetris.Rulesets.Height - 1)
	local attacks = 0

	if(lineCleared > 0) then
		local bonus = (localplayer.Bonus || lineCleared >= 4)
		localplayer.CurrentCombo = localplayer.CurrentCombo + 1
		if(bonus) then
			localplayer.CurrentB2B = localplayer.CurrentB2B + 1
			if(localplayer.CurrentCombo >= 2) then
				localplayer.ClearlineBonus = true
			end
		else
			localplayer.CurrentB2B = 0
			attacks = attacks + GTetris.OnB4BChainBreak(localplayer.CurrentB2B, GTetris.Rulesets.B4BChargeAmount)
		end
	else
		if(localplayer.CurrentCombo >= 3) then
			GTetris.ComboBreakSound()
			GTetris.OnComboBreak(localplayer.CurrentCombo)
		end
		localplayer.CurrentCombo = -1
		localplayer.ClearlineBonus = false
	end

	attacks = attacks + GTetris.GetAttacks(lineCleared, math.max(localplayer.CurrentCombo, 0), localplayer.Bonus, localplayer.CurrentB2B, GTetris.Rulesets.ComboTable)

	if(GTetris.CheckAllClear(board, GTetris.Rulesets.Width - 1, GTetris.Rulesets.Height - 1)) then
		attacks = attacks + 10
		GTetris.AllClearSound(2)
		GTetris.InsertAllClears(localplayer.boardID)
		GTetris.SendAllClear()
	end

	if(attacks > 0) then
		GTetris.ProcessAttacks(localplayer, attacks)
	end

	local canceled = 0
	if(lineCleared > 0) then
		GTetris.PlayClearSound(lineCleared, localplayer.Bonus, localplayer.CurrentCombo, localplayer.ClearlineBonus, 2)
		GTetris.SendClearLineInfo(localplayer.CurrentPiece, lineCleared, localplayer.Bonus, localplayer.CurrentCombo, localplayer.ClearlineBonus)
		GTetris.SetClearText(localplayer.boardID, lineCleared)

		for _, attack in ipairs(localplayer.ReceivedAttacks) do
			if(attack.amount <= attacks) then
				attacks = attacks - attack.amount
				canceled = canceled + attack.amount
				attack.amount = 0
			else
				attack.amount = attack.amount - attacks
				canceled = canceled + attacks
				attacks = 0
			end
			if(attacks <= 0) then
				break
			end
		end

		for i = #localplayer.ReceivedAttacks, 1, -1 do
			if(localplayer.ReceivedAttacks[i].amount <= 0) then
				table.remove(localplayer.ReceivedAttacks, i)
			end
		end
	else
		local moveup = GTetris.Rulesets.AttackCap
		local moved = false

		for _, attack in ipairs(localplayer.ReceivedAttacks) do
			if(attack.time > CurTime()) then
				continue
			end
			if(attack.amount <= moveup) then
				GTetris.MoveRowUp(localplayer.CurrentBoard, attack.amount, GTetris.Rulesets.Width, GTetris.Rulesets.Height)
				moveup = moveup - attack.amount
				attack.amount = 0
				moved = true
			else
				GTetris.MoveRowUp(localplayer.CurrentBoard, moveup, GTetris.Rulesets.Width, GTetris.Rulesets.Height)
				attack.amount = attack.amount - moveup
				moveup = 0
				moved = true
			end

			if(moveup <= 0) then
				break
			end
		end


		if(moved) then
			GTetris.BoardUpSound(4)
			GTetris.SendSound(GTetris.Enums.SOUND_BOARDUP)
		end

		for i = #localplayer.ReceivedAttacks, 1, -1 do
			if(localplayer.ReceivedAttacks[i].amount <= 0) then
				table.remove(localplayer.ReceivedAttacks, i)
			end
		end
	end

	if(attacks > 0) then
		GTetris.SendAttacks(attacks, PlaceX, PlaceY)
	end

	GTetris.AddBoardText(localplayer, PlaceX, PlaceY, canceled, true)
	GTetris.AddBoardText(localplayer, PlaceX, PlaceY, attacks, false)

	if(localplayer.Bonus) then
		GTetris.SetSpinText(localplayer.boardID, localplayer.CurrentPiece)
	end

	table.remove(localplayer.CurrentPieces, 1)
	localplayer.CurrentPiece = localplayer.CurrentPieces[1]
	localplayer.CurrentPosition.x = math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[localplayer.CurrentPiece]) / 2)
	localplayer.CurrentPosition.y = -3
	localplayer.CurrentRotationState = 4
	localplayer.Bonus = false
	localplayer.HoldUsed = false
	GTetris.PlaceblockSound(4)
	GTetris.SendSound(GTetris.Enums.SOUND_PLACE)
	GTetris.PieceResetted(localplayer)
	GTetris.SyncBoard(localplayer)
	GTetris.SyncPieceStates(localplayer)
	GTetris.SyncNextPieces(localplayer)
	GTetris.SyncBoardInfo(localplayer)
	GTetris.SyncReceivedAttacks(localplayer)
end

function GTetris.PieceResetted(localplayer)
	localplayer.AutolockTime = GTetris.Rulesets.AutolockTime
end