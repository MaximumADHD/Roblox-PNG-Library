local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local bxor = bit32.bxor

local function IDAT(file: Types.File, chunk: Types.Chunk)
	local crc = chunk.CRC
	local hash = file.Hash or 0
	
	local data = chunk.Data
	local buffer = data.Buffer
	
	file.Hash = bxor(hash, crc)
	file.ZlibStream = file.ZlibStream .. buffer
end

return IDAT