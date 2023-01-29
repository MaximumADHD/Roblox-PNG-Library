local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function sRGB(file: Types.File, chunk: Types.Chunk)
	local data = chunk.Data
	file.RenderIntent = data:ReadByte()
end

return sRGB