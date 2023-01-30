local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find
local sChar = string.char

local function tEXt(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(not tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")

	local data = chunk.Data
	local key, value = "", ""
	
	for byte in data:IterateBytes() do
		local char = sChar(byte)
		
		if char == '\0' then
			key = value
			value = ""
		else
			value = value .. char
		end
	end
	
	file.Metadata[key] = value
end

return tEXt