local function gAMA(file, chunk)
	local data = chunk.Data
	local value = data:ReadUInt32()
	file.Gamma = value / 10e4
end

return gAMA