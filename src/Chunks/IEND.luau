local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local function IEND(file: Types.File)
	file.Reading = false
end

return IEND