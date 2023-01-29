local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function tIME(file: Types.File, chunk: Types.Chunk)
	local data = chunk.Data
	
	local timeStamp = 
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