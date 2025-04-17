local strs = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f"}

function GTetris.GetRandomHex(length)
	local ret = ""
	for i = 1, length do
		ret = ret .. strs[math.random(1, #strs)]
	end
	return ret
end

function GTetris.CompressTable(tab)
	local data = util.TableToJSON(tab)
	local compressed = util.Compress(data)
	return compressed, string.len(compressed)
end

function GTetris.DecompressTable(data)
	local decompressed = util.Decompress(data)
	local tab = util.JSONToTable(decompressed)
	return tab
end

GTetris.DataType_BOOL = 1
GTetris.DataType_INT = 2
GTetris.DataType_FLOAT = 3
GTetris.DataType_STRING = 4
GTetris.WriteFuncs = {
	[GTetris.DataType_BOOL] = function(val)
		net.WriteBool(val)
	end,
	[GTetris.DataType_INT] = function(val)
		net.WriteInt(val, 32)
	end,
	[GTetris.DataType_FLOAT] = function(val)
		net.WriteFloat(val)
	end,
	[GTetris.DataType_STRING] = function(val)
		net.WriteString(val)
	end,
}
GTetris.ReadFuncs = {
	[GTetris.DataType_BOOL] = function()
		return net.ReadBool()
	end,
	[GTetris.DataType_INT] = function()
		return net.ReadInt(32)
	end,
	[GTetris.DataType_FLOAT] = function()
		return net.ReadFloat()
	end,
	[GTetris.DataType_STRING] = function()
		return net.ReadString()
	end,
}

function GTetris.ConvertToServerPointer(pointer)
	return string.Replace(pointer, "Rulesets", "ruleset")
end

function GTetris.GetPointerValue(startingPointer, pointerStr)
	local pointer = startingPointer
	local keys = string.Explode("->", pointerStr)
	for _, key in pairs(keys) do
		pointer = pointer[key]
	end
	return pointer
end
function GTetris.SetPointerValue(startingPointer, pointerStr, newval)
	local pointer = startingPointer
	local keys = string.Explode("->", pointerStr)
	for _, key in pairs(keys) do
		if(_ == #keys) then
			pointer[key] = newval
		else
			pointer = pointer[key]
		end
	end
end