local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function gAMA(file: Types.File, chunk: Types.Chunk)
	local data = chunk.Data
	local value = data:ReadUInt32()
	file.Gamma = value / 10e4
end

return gAMA