--!strict

local modules = script.Parent

local Types = require(modules.Types)

local mmin = math.min

local BinaryReader: Types.BinaryReaderImpl = {} :: Types.BinaryReaderImpl
BinaryReader.__index = BinaryReader

function BinaryReader.new(buffer: string): Types.BinaryReader
	local self = setmetatable({}, BinaryReader)

	self.Position = 1
	self.Buffer = buffer
	self.Length = #buffer

	return self
end

function BinaryReader:ReadByte(): number?
	local buffer = self.Buffer
	local pos = self.Position

	if pos <= self.Length then
		local result = buffer:sub(pos, pos)
		self.Position = pos + 1

		return result:byte()
	end

	return nil
end

function BinaryReader:ReadBytes(count: number): { number }
	local values = {}

	for i = 1, count do
		values[i] = self:ReadByte() :: number
	end

	return values
end

function BinaryReader:PeekByte(): number?
	local buffer = self.Buffer
	local pos = self.Position

	return buffer:sub(pos, pos):byte()
end

function BinaryReader:PeekBytes(count: number): { number }
	local buffer = self.Buffer

	return { buffer:sub(self.Position, self.Position + count):byte() }
end

function BinaryReader:ReadAllBytes(): { number }
	return self:ReadBytes(self.Length)
end

function BinaryReader:IterateBytes(): () -> number?
	return function()
		return self:ReadByte()
	end
end

function BinaryReader:TwosComplementOf(value: number, numBits: number): number
	if value >= (2 ^ (numBits - 1)) then
		value = value - (2 ^ numBits)
	end

	return value
end

function BinaryReader:ReadUInt16(): number
	local bytes = self:ReadBytes(2)
	return (bytes[1] * 256) + bytes[2]
end

function BinaryReader:ReadInt16(): number
	local unsigned = self:ReadUInt16()
	return self:TwosComplementOf(unsigned, 16)
end

function BinaryReader:ReadUInt32(): number
	local upper = self:ReadUInt16()
	local lower = self:ReadUInt16()

	return (upper * 65536) + lower
end

function BinaryReader:ReadInt32(): number
	local unsigned = self:ReadUInt32()
	return self:TwosComplementOf(unsigned, 32)
end

function BinaryReader:ReadString(length: number): string
	if length == nil then
		length = self:ReadByte() or 0
	end

	local pos = self.Position
	local nextPos = mmin(self.Length, pos + length)

	local result = self.Buffer:sub(pos, nextPos - 1)
	self.Position = nextPos

	return result
end

function BinaryReader:ForkReader(length: number): Types.BinaryReader
	local chunk = self:ReadString(length)
	return BinaryReader.new(chunk)
end

return BinaryReader
