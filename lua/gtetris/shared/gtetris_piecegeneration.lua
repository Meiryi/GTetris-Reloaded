GTetris.Bag1X = {1, 2, 3, 4, 5, 6, 7}
GTetris.Bag2X = {1, 2, 3, 4, 5, 6, 7, 1 ,2 ,3 ,4 ,5, 6, 7}
GTetris.Bag5X = {1, 2, 3, 4, 5, 6, 7, 1 ,2 ,3 ,4 ,5, 6, 7, 1 ,2 ,3 ,4 ,5, 6, 7, 1 ,2 ,3 ,4 ,5, 6, 7, 1 ,2 ,3 ,4 ,5, 6, 7}

function GTetris.GeneratePieces(rule, seed)
	local newbag = {}
	if(rule == GTetris.Enums.BAGSYS_7BAG) then
		newbag = table.Copy(GTetris.Bag1X)
	elseif(rule == GTetris.Enums.BAGSYS_14BAG) then
		newbag = table.Copy(GTetris.Bag2X)
	elseif(rule == GTetris.Enums.BAGSYS_35BAG) then
		newbag = table.Copy(GTetris.Bag5X)
	else -- Completely random
		newbag = {}
		for i = 1, 7 do
			table.insert(newbag, math.random(1, 7))
		end
	end

	local _seed = seed
	local n = #newbag
	for i = 1, n - 1 do
		math.randomseed(_seed)
		local j = math.random(i, n)
		newbag[i], newbag[j] = newbag[j], newbag[i]
		_seed = _seed + 1
	end

	return newbag
end