local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function tIME(file: Types.File, chunk: Types.Chunk, state: Types.ChunkReaderState)
	assert(not tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
	assert(not tfind(state.FoundChunkType, "tIME"), "There can only be one tIME chunk in a PNG file")

	local data = chunk.Data
	
	local timeStamp: Types.TimeStamp = 
	{
		Year  = data:ReadUInt16();
		Month = data:ReadByte();
		Day   = data:ReadByte();
		
		Hour   = data:ReadByte();
		Minute = data:ReadByte();
		Second = data:ReadByte();
	}
	
	file.TimeStamp = timeStamp
end

return tIME