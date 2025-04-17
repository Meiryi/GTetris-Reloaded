GTetris.BoardLayer = GTetris.BoardLayer || {}

local draw_RoundedBox = draw.RoundedBox
local blockMat = Material("gtetris/block.png")
local allclearMat = Material("gtetris/allclear.png")
function GTetris.SetupBoardLayer(attachTo)
	if(!IsValid(GTetris.MainUI)) then return end
	local scrw, scrh = ScrW(), ScrH()
	local layer = GTetris.CreateFrame(attachTo, 0, 0, scrw, scrh, color_transparent)
		layer:SetZPos(1)
		layer.Boards = {}
		layer.FocusingBoard = nil
		layer.Amount = 0

		layer.BoardWidth = GTetris.Rulesets.Width
		layer.BoardHeight = GTetris.Rulesets.Height
		layer.BoardBlockSize = ScreenScaleH(16)

		layer.BoardWide = layer.BoardBlockSize * layer.BoardWidth
		layer.BoardTall = layer.BoardBlockSize * layer.BoardHeight
		layer.InputBlockTime = 0

		layer.GetLocalPlayer = function()
			local localply = layer.Boards[LocalPlayer():SteamID64()]
			return localply || layer.Boards[layer.LocalPlayerID]
		end

		layer.UpdateBoardAmounts = function(amount)
			if(!IsValid(layer)) then return end
			layer.Amount = amount
		end

		layer.GetBoardRenderTarget = function(index)
			return GetRenderTarget("GTetrisBoardRT"..index, scrw, scrh)
		end

		layer.GetBoard = function(boardID)
			return layer.Boards[boardID]
		end

		layer.SetupDefaultBoard = function(boardID)
			if(!IsValid(layer.Boards[boardID])) then return end
			local board = layer.Boards[boardID]
			for rows = 0, layer.BoardWidth - 1 do
				for cols = -20, layer.BoardHeight - 1 do
					if(!board.CurrentBoard[cols]) then
						board.CurrentBoard[cols] = {}
					end
					board.CurrentBoard[cols][rows] = 0
				end
			end
		end

		layer.Sorting = false
		layer.SortingTime = 0.45
		layer.CurrentSortingTime = 0
		layer.SortBoards = function(instant)
			layer.CurrentSortingTime = SysTime() + layer.SortingTime
			if(instant) then
				layer.CurrentSortingTime = -1
			end
			layer.Sorting = true
			local amount = layer.Amount
			local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
			local maxColumns = 3
			local currentCol = 0
			local currentRow = 0
			local _x, _y = 0, 0
			local pad_offset = 0
			local init = true
			local center = centerX - layer.BoardWide * 0.5
			local scale = 1 / (math.Clamp(amount - 1, 1, 3))
			local rows = math.ceil((amount - 1) / maxColumns) -- -1 for the local player or the focused board
			local scaled_tall = layer.BoardTall * scale
			local gap = ScreenScaleH(16)
			_x = center + layer.BoardWide * 1.75
			_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
			pad_offset = (scrh * 0.5) * (1 - scale)

			for _, board in pairs(layer.Boards) do
				board.PreSortPosX = board:GetX()
				board.PreSortPosY = board:GetY()
				if(amount <= 1) then
					board.TargetScale = 1
					board.TargetX = centerX - board:GetWide() * 0.5
					board.TargetY = centerY - board:GetTall() * 0.5
				elseif(amount <= 2) then
					local center = centerX - board:GetWide() * 0.5
					if(board == layer.FocusingBoard) then
						board.TargetX = center - board:GetWide() * 1.15
					else
						board.TargetX = center + board:GetWide() * 1.15
					end
					board.TargetY = centerY - board:GetTall() * 0.5
					board.TargetScale = 1
				elseif(amount <= 10) then
					if(board == layer.FocusingBoard) then
						board.TargetX = center
						board.TargetY = centerY - board:GetTall() * 0.5
						board.TargetScale = 1
					else
						board.TargetX = _x
						board.TargetY = _y
						board.TargetScale = scale
						_y = _y + scaled_tall + gap
						currentCol = currentCol + 1
						if(currentCol >= maxColumns) then
							_x = _x + layer.BoardWide * scale + gap
							_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
							currentCol = 0
						end
					end
				else
					if(board == layer.FocusingBoard) then
						board.TargetX = center
						board.TargetY = centerY - board:GetTall() * 0.5
						board.TargetScale = 1
					else
						board.TargetX = _x
						board.TargetY = _y
						board.TargetScale = scale
						_y = _y + scaled_tall + gap
						currentCol = currentCol + 1
						if(currentCol >= maxColumns) then
							_x = _x + layer.BoardWide * scale + gap
							_y = scrh * 0.5 - layer.BoardTall * 0.5 - gap
							currentCol = 0
							currentRow = currentRow + 1
							if(currentRow >= 3) then
								_x = centerX - layer.BoardWide * 1.75 - layer.BoardWide * 0.5 - ScreenScaleH(24)
								currentRow = 0
							end
						end
					end
				end
			end
		end

		layer.BoardIndex = 1
		layer.CreateBoard = function(boardID, localplayer)
			local board = GTetris.CreatePanel(layer, 0, 0, 1, 1, Color(255, 0, 0, 255))
				board.TargetWidth = layer.BoardBlockSize * layer.BoardWidth
				board.TargetHeight = layer.BoardBlockSize * layer.BoardHeight
				board:SetSize(layer.BoardBlockSize * layer.BoardWidth, layer.BoardBlockSize * layer.BoardHeight)
				board.TargetX = 0
				board.TargetY = 0
				board.TargetScale = 1
				board.CurrentScale = 0.0
				board.boardID = boardID

				board:NoClipping(true)

				board.PlayerNick = nil
				board.Alive = true
				board.CurrentBoard = {}

				board.CurrentRotationState = 4
				board.CurrentSeed = GTetris.Rulesets.Seed
				board.CurrentPieces = GTetris.GeneratePieces(GTetris.Rulesets.BagSystem, board.CurrentSeed)
				board.CurrentPiece = board.CurrentPieces[1]
				board.CurrentPosition = {x = math.floor((GTetris.Rulesets.Width - GTetris.BlockWidth[board.CurrentPiece]) * 0.5), y = -3}
				board.CurrentHoldPiece = -1
				board.ClearlineBonus = false
				board.HoldUsed = false

				board.RotationRule = GTetris.Rulesets.SpinSystem

				board.Index = layer.BoardIndex
				board.CurrentCombo = -1
				board.CurrentB2B = 0
				board.CurrentB2BAlpha = 0
				board.CurrentB2BFlash = false
				board.CurrentB2BFlashTime = 0
				board.AutolockTime = GTetris.Rulesets.AutolockTime
				board.GravityTime = 0

				board.LastSpin = ""

				board.TotalAttacks = 0
				board.TotalBlockPlaced = 0
				board.StartPlayingTime = 0

				board.SpinText = ""
				board.SpinTextColor = color_white
				board.SpinTextAlpha = 0
				board.SpinXOffset = 0

				board.ComboAlpha = 0

				board.ClearText = ""
				board.ClearTextAlpha = 0
				board.ClearXOffset = 0

				board.Numbers = {}
				board.AllClears = {}
				board.ReceivedAttacks = {}

				board.UpdateBoard = function()
					board.ShouldRenderBoard = true
				end

				local AttackBarWide = layer.BoardBlockSize * 0.75
				board.Paint2x = function()
					local BlockSize = layer.BoardBlockSize
					local CurrentFraction = board:GetTall() / board.TargetHeight
					board.CurrentBlockSize = BlockSize
					board.InputEnabled = layer.InputBlockTime < SysTime()

					if(board.TargetScale < board.CurrentScale) then
						board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2, board.TargetScale, board.CurrentScale)
					else
						board.CurrentScale = GTetris.IncFV(board.CurrentScale, (board.TargetScale - board.CurrentScale) * 0.2, board.CurrentScale, board.TargetScale)
					end

					if(board.ShouldRenderBoard) then
						local rt = layer.GetBoardRenderTarget(board.Index)

						render.PushRenderTarget(rt)
							cam.Start2D()
								for col, rows in ipairs(board.CurrentBoard) do
									for row, id in ipairs(rows) do
										local color = GTetris.Blocks_Colors[id]
										if(color) then
											local x = (row - 1) * BlockSize
											local y = (col - 1) * BlockSize
											draw_RoundedBox(0, x, y, BlockSize, BlockSize, color)
										end
									end
								end
							cam.End2D()
						render.PopRenderTarget()

						if(!board.RTReference) then
							board.RTReference = CreateMaterial("GTetrisBoardRT"..math.random(1, 2147483646), "VertexLitGeneric", {
							    ["$basetexture"] = rt:GetName(),
							    ["$translucent"] = 1,
							})
						end
						board.ShouldRenderBoard = nil
					end

					if(board.RTReference) then
						local totalWide = layer.BoardWidth * BlockSize
						local totalTall = layer.BoardHeight * BlockSize
						local lineSize = ScreenScaleH(1)
						local lineTall = totalTall + lineSize

						local gridColor = Color(155, 155, 155, 255)
						if(layer.Amount >= 4 && board != layer.FocusingBoard) then
							gridColor = Color(80, 80, 80, 255)
						end
						local matrix = Matrix()
							matrix:SetScale(Vector(board.CurrentScale, board.CurrentScale, 1))
							matrix:SetTranslation(Vector(board.CurrentXOffset || 0, board.CurrentYOffset || 0, 0))
							cam.PushModelMatrix(matrix)
								draw_RoundedBox(0, 0, 0, totalWide, totalTall, Color(30, 30, 30, 255))
								if(!GTetris.OldRenderingMethod) then
									surface.SetDrawColor(255, 255, 255, 255)
									surface.SetMaterial(board.RTReference)
									surface.DrawTexturedRect(0, 0, scrw, scrh)
								else
									surface.SetMaterial(blockMat)
									for i = -20, layer.BoardHeight  do
										local rows = board.CurrentBoard[i]
										if(!rows) then continue end
										for col = 0, layer.BoardWidth - 1 do
											local id = rows[col]
											if(id == 0) then continue end
											local color = GTetris.Blocks_Colors[id]
											local x = col * BlockSize
											local y = i * BlockSize
											surface.SetDrawColor(color.r, color.g, color.b, color.a)
											surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
										end
									end
								end

								if(layer.Amount <= 4 || board == layer.FocusingBoard) then
									local nextPiece_Width = layer.BoardBlockSize * 5
									local nextPiece_Height = layer.BoardBlockSize * 16
									local x = board:GetX() + board:GetWide()
									local y = board:GetY()
									local piece_padding = BlockSize * 3
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", "Next Pieces")
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, gridColor)
									draw.DrawText("Next Pieces", "GTetris_UIFontMedium", x + nextPiece_Width * 0.5, 0, color_black, TEXT_ALIGN_CENTER)
									x = x + lineSize * 2
									y = y + th + lineSize
									nextPiece_Width = nextPiece_Width - lineSize * 3
									nextPiece_Height = nextPiece_Height - th - lineSize * 2
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, Color(0, 0, 0, 255))

									y = y + BlockSize * 0.45

									surface.SetMaterial(blockMat)

									local count = 0
									for num, piece in ipairs(board.CurrentPieces) do
										if(num == 1) then continue end
										local shape = GTetris.Blocks[piece][4]
										local color = GTetris.Blocks_Colors[piece]
										local draw_x = x + (nextPiece_Width - (GTetris.BlockWidth[piece] * BlockSize)) * 0.5
										surface.SetDrawColor(color.r, color.g, color.b, color.a)
										for _, shape in ipairs(shape) do
											local x = shape[1] * BlockSize + draw_x
											surface.DrawTexturedRect(x, y + shape[2] * BlockSize + (count * piece_padding), BlockSize, BlockSize)
										end
										count = count + 1
										if(count >= 5) then
											break
										end
									end

									x = board:GetX() - AttackBarWide
									y = board:GetY()
									local nextPiece_Width = layer.BoardBlockSize * 5
									local nextPiece_Height = layer.BoardBlockSize * 4
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", "Hold Piece")
									draw_RoundedBox(0, x - nextPiece_Width, y, nextPiece_Width, nextPiece_Height, gridColor)
									draw.DrawText("Hold Piece", "GTetris_UIFontMedium", x - nextPiece_Width * 0.5, 0, color_black, TEXT_ALIGN_CENTER)
									x = x - nextPiece_Width + lineSize * 2
									y = y + th + lineSize
									nextPiece_Width = nextPiece_Width - lineSize * 3
									nextPiece_Height = nextPiece_Height - th - lineSize * 2
									draw_RoundedBox(0, x, y, nextPiece_Width, nextPiece_Height, Color(0, 0, 0, 255))
									y = y + BlockSize * 0.5
									if(board.CurrentHoldPiece != -1) then
										local shape = GTetris.Blocks[board.CurrentHoldPiece][4]
										local color = GTetris.Blocks_Colors[board.CurrentHoldPiece]
										local draw_x = x + (nextPiece_Width - (GTetris.BlockWidth[board.CurrentHoldPiece] * BlockSize)) * 0.5
										if(!board.HoldUsed) then
											surface.SetDrawColor(color.r, color.g, color.b, color.a)
										else
											surface.SetDrawColor(100, 100, 100, 255)
										end
										for _, shape in ipairs(shape) do
											local x = shape[1] * BlockSize + draw_x
											surface.DrawTexturedRect(x, y + shape[2] * BlockSize, BlockSize, BlockSize)
										end
									end
								end

								for i = 0, layer.BoardWidth do
									draw_RoundedBox(0, i * BlockSize, 0, lineSize, lineTall, gridColor)
								end
								for i = 0, layer.BoardHeight do
									draw_RoundedBox(0, 0, i * BlockSize, totalWide, lineSize, gridColor)
								end

							if(board == layer.FocusingBoard) then
								local PlaceY = GTetris.TraceToBottom(board)
								local shape = GTetris.Blocks[board.CurrentPiece][board.CurrentRotationState]
								local origin = board.CurrentPosition
								local color = GTetris.Blocks_Colors[board.CurrentPiece]
								surface.SetMaterial(blockMat)
								surface.SetDrawColor(color.r, color.g, color.b, 50)
								for _, block in ipairs(shape) do
									local x = (block[1] + origin.x) * BlockSize
									local y = (block[2] + PlaceY) * BlockSize
									surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
								end
							end

							if(board.Alive && (layer.Amount <= 4 || board == layer.FocusingBoard)) then
								local origin, shape, rotation = board.CurrentPosition, GTetris.Blocks[board.CurrentPiece], board.CurrentRotationState
								surface.SetMaterial(blockMat)
								for _, block in ipairs(shape[rotation]) do
									local x = (block[1] + origin.x) * BlockSize
									local y = (block[2] + origin.y) * BlockSize
									local color = GTetris.Blocks_Colors[board.CurrentPiece]
									surface.SetDrawColor(color.r, color.g, color.b, color.a)
									surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
								end

								if(board.PlayerNick) then
									local gap = ScreenScaleH(4)
									local tw, th = GTetris.GetTextSize("GTetris_UIFontMedium", board.PlayerNick)
									tw = tw + gap * 2
									th = th + gap * 2
									local x, y = board:GetWide() * 0.5, board:GetTall() + gap
									draw_RoundedBox(0, x - (tw * 0.5), y, tw, th, Color(0, 0, 0, 200))
									draw.DrawText(board.PlayerNick, "GTetris_UIFontMedium", x, y + gap, color_white, TEXT_ALIGN_CENTER)
								end

								local x, y = -AttackBarWide, board:GetTall()
								local systime = SysTime()
								draw_RoundedBox(0, x, 0, AttackBarWide, board:GetTall(), Color(30, 30, 30, 255))
								draw_RoundedBox(0, x, y - GTetris.Rulesets.AttackCap * BlockSize, AttackBarWide, lineSize, gridColor)
								y = y + lineSize
								for _, attack in ipairs(board.ReceivedAttacks) do
									local tall = attack.amount * BlockSize - lineSize
									if(attack.time < systime) then
										draw_RoundedBox(0, x, y - tall, AttackBarWide, tall, Color(255, 50, 50, 255))
									else
										draw_RoundedBox(0, x, y - tall, AttackBarWide, tall, Color(255, 50, 50, 50))
									end
									y = y - tall - lineSize
								end
								surface.SetDrawColor(gridColor.r, gridColor.g, gridColor.b, 255)
								surface.DrawOutlinedRect(x, 0, AttackBarWide, board:GetTall() + lineSize, lineSize)

								local blockSize = BlockSize * board.CurrentScale
								for _, number in ipairs(board.Numbers) do
									if(number.time > systime) then
										number.alpha = GTetris.IncFV(number.alpha, 15, 0, 255)
									else
										number.alpha = GTetris.IncFV(number.alpha, -15, 0, 255)
										if(number.alpha <= 0) then
											table.remove(board.Numbers, _)
										end
									end
									number.scale = GTetris.IncFV(number.scale, 0.075, 0, 0.5)
									local scale = number.scale * board.CurrentScale
									local color = color_white
									if(number.cancel) then
										color = Color(120, 180, 255, 255)
									end
									local translation = matrix:GetTranslation()
									local numMatrix = Matrix()
										numMatrix:SetTranslation(Vector(translation.x + (number.x + 2) * blockSize, translation.y + number.y * blockSize, 0))
										numMatrix:SetScale(Vector(scale, scale, 1))
										numMatrix:Rotate(Angle(0, number.rotation, 0))
										cam.PushModelMatrix(numMatrix)
											draw.SimpleTextOutlined(number.num, "GTetris_AttackNumberFont", 0, 0, Color(color.r, color.g, color.b, number.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
										cam.PopModelMatrix()
								end
							end

							if(localplayer && board.Alive && board.InputEnabled) then
								local origin = board.CurrentPosition
								local shape = GTetris.Blocks[board.CurrentPiece][board.CurrentRotationState]
								if(!GTetris.TestCollision(board.CurrentBoard, shape, origin.x, origin.y + 1)) then
									board.AutolockTime = board.AutolockTime - RealFrameTime()
									if(board.AutolockTime <= 0) then
										GTetris.PlacePiece(board)
									end
								end

								local time = SysTime()
								if(board.GravityTime < time && GTetris.Rulesets.Gravity > 0) then
									if(GTetris.MovePiece(board, 0, 1)) then
										GTetris.PieceMoved(board, true)
									end
									board.GravityTime = time + (1 / GTetris.Rulesets.Gravity)
								end
							end

							local gap = ScreenScaleH(14)
							local text_x = -gap
							local text_y = board:GetTall() * 0.235

							if(board.SpinTextAlpha > 0) then
								local clr = board.SpinTextColor
								draw.DrawText(board.SpinText, "GTetris_BoardSpin", text_x - board.SpinXOffset, text_y, Color(clr.r, clr.g, clr.b, board.SpinTextAlpha), TEXT_ALIGN_RIGHT)
								board.SpinTextAlpha = GTetris.IncFV(board.SpinTextAlpha, -3, 0, 255)
								board.SpinXOffset = board.SpinXOffset + GTetris.GetFixedValue(ScreenScaleH(1)) * 0.125
							end

							text_y = board:GetTall() * 0.285

							if(board.ClearTextAlpha > 0) then
								draw.DrawText(board.ClearText, "GTetris_BoardClearLine", text_x - board.ClearXOffset, text_y, Color(255, 255, 255, board.ClearTextAlpha), TEXT_ALIGN_RIGHT)
								board.ClearTextAlpha = GTetris.IncFV(board.ClearTextAlpha, -3, 0, 255)
								board.ClearXOffset = board.ClearXOffset + GTetris.GetFixedValue(ScreenScaleH(1)) * 0.125
							end

							text_y = board:GetTall() * 0.365

							if(board.CurrentB2B > 0) then
								board.CurrentB2BAlpha = GTetris.IncFV(board.CurrentB2BAlpha, 15, 0, 255)
							else
								board.CurrentB2BAlpha = GTetris.IncFV(board.CurrentB2BAlpha, -5, 0, 255)
							end

							if(board.CurrentB2BAlpha > 0) then
								if(board.CurrentB2B > 0) then
									draw.DrawText("B2B x "..board.CurrentB2B, "GTetris_BoardSpin", text_x, text_y, Color(255, 160, 0, board.CurrentB2BAlpha), TEXT_ALIGN_RIGHT)
								else 
									if(((SysTime() % 0.2) / 0.2) > 0.5) then
										draw.DrawText("B2B x "..board.CurrentB2B, "GTetris_BoardSpin", text_x, text_y, Color(255, 50, 50, board.CurrentB2BAlpha), TEXT_ALIGN_RIGHT)
									end
								end
							end

							text_y = board:GetTall() * 0.425

							if(board.CurrentCombo > 0) then
								board.ComboAlpha = GTetris.IncFV(board.ComboAlpha, 15, 0, 255)
							else
								board.ComboAlpha = GTetris.IncFV(board.ComboAlpha, -10, 0, 255)
							end

							if(board.ComboAlpha > 0) then
								if(board.CurrentCombo > 0) then
									draw.DrawText("Combo x "..board.CurrentCombo, "GTetris_BoardCombo", text_x, text_y, Color(255, 255, 255, board.ComboAlpha), TEXT_ALIGN_RIGHT)
								else
									draw.DrawText("Combo x 0", "GTetris_BoardCombo", text_x, text_y, Color(255, 50, 50, board.ComboAlpha), TEXT_ALIGN_RIGHT)
								end
							end

							local ax, ay = board:GetWide() * 0.5, board:GetTall() * 0.5
							local size = board:GetTall() * 0.5
							surface.SetMaterial(allclearMat)
							--[[
								scale = 0.2,
								scale2 = 1,
								decaytime = SysTime() + 1,
								rotation = 360,
								alpha1 = 255,
								alpha2 = 255,
							]]
							for _, pc in ipairs(board.AllClears) do
								if(pc.decaytime < SysTime()) then
									pc.scale = GTetris.IncFV(pc.scale, -0.015, 0.1, 1.5)
									pc.alpha1 = GTetris.IncFV(pc.alpha1, -6, 0, 255)
									if(pc.alpha1 <= 0) then
										table.remove(board.AllClears, _)
									end
								else
									if(pc.rotation <= 0) then
										pc.scale = GTetris.IncFV(pc.scale, -0.002, 0.1, 1.5)
									else
										pc.scale = GTetris.IncFV(pc.scale, 0.075, 0.2, 1.5)
									end
								end

								if(pc.rotation <= 0) then
									surface.SetDrawColor(51, 43, 0, pc.alpha2)
									surface.DrawTexturedRectRotated(ax, ay, size * pc.scale2, size * pc.scale2, pc.rotation)
									pc.scale2 = pc.scale2 + GTetris.GetFixedValue(0.02)
									pc.alpha2 = GTetris.IncFV(pc.alpha2, -4, 0, 255)
								else
									pc.scale2 = pc.scale
								end

								pc.rotation = GTetris.IncFV(pc.rotation, -30, 0, 360)
								surface.SetDrawColor(255, 215, 0, pc.alpha1)
								surface.DrawTexturedRectRotated(ax, ay, size * pc.scale, size * pc.scale, pc.rotation)
							end

							cam.PopModelMatrix()
					end
				end

			layer.Amount = layer.Amount + 1
			layer.BoardIndex = layer.BoardIndex + 1
			layer.Boards[boardID] = board
			if(localplayer) then
				layer.FocusingBoard = board
			end
			layer.SetupDefaultBoard(boardID)
			board.UpdateBoard()
			return board
		end

		layer.Think = function()
			if(layer.Sorting) then
				local fraction = math.ease.InCubic(math.Clamp(1 - (layer.CurrentSortingTime - SysTime()) / layer.SortingTime, 0, 1))
				for _, board in pairs(layer.Boards) do
					local offsetX = board.PreSortPosX - board.TargetX
					local offsetY = board.PreSortPosY - board.TargetY
					board.CurrentXOffset = board.PreSortPosX - offsetX * fraction
					board.CurrentYOffset = board.PreSortPosY - offsetY * fraction
				end
				if(layer.CurrentSortingTime < SysTime()) then
					for _, board in pairs(layer.Boards) do
						board.CurrentXOffset = board.TargetX
						board.CurrentYOffset = board.TargetY
					end
					layer.Sorting = false
				end
			end
		end

	GTetris.BoardLayer = layer
	return layer
end

function GTetris.SetupDefaultBoard(board)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.GetLocalPlayer()
	if(!IsValid(GTetris.BoardLayer)) then return end
	return GTetris.BoardLayer.GetLocalPlayer()
end

function GTetris.DestroyBoardLayer()
	if(!IsValid(GTetris.BoardLayer)) then return end
	GTetris.BoardLayer:Remove()
end

function GTetris.SortBoards(instant)
	if(!IsValid(GTetris.BoardLayer)) then return end
	GTetris.BoardLayer.SortBoards(instant)
end

function GTetris.UpdateBoardAmounts(amount)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.CreateBoard(boardID, localplayer)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.CreateBoard(boardID, localplayer)
	return board
end

function GTetris.RemoveBoardFromSortList(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.SetSpinText(boardID, piece)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	board.SpinText = (GTetris.BlockIDs[piece] || "?").." - Spin"
	board.SpinTextAlpha = 255
	board.SpinTextColor = GTetris.Blocks_Colors[piece] || color_white
	board.SpinXOffset = 0
end

local texts = {
	"Single",
	"Double",
	"Triple",
	"Quad",
}
function GTetris.SetClearText(boardID, lines)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	local text = texts[lines] || lines
	board.ClearText = text
	board.ClearTextAlpha = 255
	board.ClearXOffset = 0
end

function GTetris.InsertAllClears(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end
	local board = GTetris.BoardLayer.GetBoard(boardID)
	if(!IsValid(board)) then return end
	table.insert(board.AllClears, {
		scale = 0.1,
		scale2 = 1,
		decaytime = SysTime() + 1.5,
		rotation = 360,
		alpha1 = 255,
		alpha2 = 175,
	})
end

function GTetris.GetBoard(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end
	return GTetris.BoardLayer.GetBoard(boardID)
end