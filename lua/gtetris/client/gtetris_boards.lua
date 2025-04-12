GTetris.BoardLayer = GTetris.BoardLayer || {}

local draw_RoundedBox = draw.RoundedBox
local blockMat = Material("gtetris/block.png")
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
			return layer.Boards[LocalPlayer():SteamID64()]
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
				print(rows)
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

				board:NoClipping(true)

				board.PlayerNick = "Unknown Player"
				board.Alive = true
				board.CurrentBoard = {}

				board.CurrentPiece = 1
				board.CurrentPosition = {x = 0, y = 0}
				board.CurrentRotationState = 1
				board.CurrentSeed = GTetris.Rulesets.Seed
				board.RotationRule = GTetris.Rulesets.SpinSystem

				board.Index = layer.BoardIndex
				board.CurrentCombo = 0
				board.CurrentB2B = 0

				board.LastSpin = ""

				board.TotalAttacks = 0
				board.TotalBlockPlaced = 0
				board.StartPlayingTime = 0

				board.UpdateBoard = function()
					board.ShouldRenderBoard = true
				end

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
								for i = 0, layer.BoardWidth do
									draw_RoundedBox(0, i * BlockSize, 0, lineSize, lineTall, gridColor)
								end
								for i = 0, layer.BoardHeight do
									draw_RoundedBox(0, 0, i * BlockSize, totalWide, lineSize, gridColor)
								end

							if(board.Alive) then
								local origin, shape, rotation = board.CurrentPosition, GTetris.Blocks[board.CurrentPiece], board.CurrentRotationState
								surface.SetMaterial(blockMat)
								for _, block in ipairs(shape[rotation]) do
									local x = (block[1] + origin.x) * BlockSize
									local y = (block[2] + origin.y) * BlockSize
									local color = GTetris.Blocks_Colors[board.CurrentPiece]
									surface.SetDrawColor(color.r, color.g, color.b, color.a)
									surface.DrawTexturedRect(x, y, BlockSize, BlockSize)
								end
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
end

function GTetris.RemoveBoardFromSortList(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end

end

function GTetris.GetBoard(boardID)
	if(!IsValid(GTetris.BoardLayer)) then return end
	return GTetris.BoardLayer.GetBoard(boardID)
end