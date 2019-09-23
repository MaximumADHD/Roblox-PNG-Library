local BinaryReader = {}
BinaryReader.__index = BinaryReader

function BinaryReader.new(buffer)
	local reader = 
	{
		Position = 1;
		Buffer = buffer;
		Length = #buffer;
	}
	
	return setmetatable(reader, BinaryReader)
end

function BinaryReader:ReadByte()
	local buffer = self.Buffer
	local pos = self.Position
	
	if pos <= self.Length then
		local result = buffer:sub(pos, pos)
		self.Position = pos + 1
		
		return result:byte()
	end
end

function BinaryReader:ReadBytes(count, asArray)
	local values = {}
	
	for i = 1, count do
		values[i] = self:ReadByte()
	end
	
	if asArray then
		return values
	end
	
	return unpack(values)
end

function BinaryReader:ReadAllBytes()
	return self:ReadBytes(self.Length, true)
end

function BinaryReader:IterateBytes()
	return function ()
		return self:ReadByte()
	end
end

function BinaryReader:TwosComplementOf(value, numBits)
	if value >= (2 ^ (numBits - 1)) then
		value = value - (2 ^ numBits)
	end
	
	return value
end

function BinaryReader:ReadUInt16()
	local upper, lower = self:ReadBytes(2)
	return (upper * 256) + lower
end

function BinaryReader:ReadInt16()
	local unsigned = self:ReadUInt16()
	return self:TwosComplementOf(unsigned, 16)
end

function BinaryReader:ReadUInt32()
	local upper = self:ReadUInt16()
	local lower = self:ReadUInt16()
	
	return (upper * 65536) + lower
end

function BinaryReader:ReadInt32()
	local unsigned = self:ReadUInt32()
	return self:TwosComplementOf(unsigned, 32)
end

function BinaryReader:ReadString(length)
    if length == nil then
        length = self:ReadByte()
    end
    
    local pos = self.Position
    local nextPos = math.min(self.Length, pos + length)
    
    local result = self.Buffer:sub(pos, nextPos - 1)
    self.Position = nextPos
    
    return result
end

function BinaryReader:ForkReader(length)
	local chunk = self:ReadString(length)
	return BinaryReader.new(chunk)
end

return BinaryReader