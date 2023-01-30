local modules = script.Parent.Parent.Modules

local Types = require(modules.Types)

local tfind = table.find

local function pHYs(_: Types.File, _: Types.Chunk, state: Types.ChunkReaderState)
    assert(tfind(state.FoundChunkType, "IHDR"), "Missing IHDR chunk")
    assert(not tfind(state.FoundChunkType, "pHYs"), "There can only be one pHYs chunk in a PNG file")
    assert(not tfind(state.FoundChunkType, "IDAT"), "pHYs chunk must be before IDAT chunks")

    -- local x = chunk.Data:ReadUInt32()
    -- local y = chunk.Data:ReadUInt32()
    -- local unit = chunk.Data:ReadByte()

    warn("Chunk type 'pHYs' is not implemented yet")
end

return pHYs