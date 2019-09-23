local function tIME(file, chunk)
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