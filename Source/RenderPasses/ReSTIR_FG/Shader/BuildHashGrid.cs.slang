import FinalGatherData;
import HashBuildStructure;
import Utils.Debug.PixelDebug;

cbuffer PerFrame
{
    uint gFrameCount;                   // Current it for sample gen
    uint2 gFrameDim;                    // Frame Dimensions for camera dir
}

StructuredBuffer<HashAppendData> gAppendBuffer;
RWStructuredBuffer<uint> gCellStorageBuffer;
ByteAddressBuffer gCellIndexBuffer;

[numthreads(16, 16, 1)]
void main(uint2 pixel : SV_DispatchThreadID)
{
    printSetPixel(pixel);

    HashAppendData data = gAppendBuffer[index2Dto1D(pixel, gFrameDim.x)];
    if (data.isValid == 0)
        return;

    uint baseIdx = gCellIndexBuffer.Load(data.cellIdx);
    gCellStorageBuffer[baseIdx + data.inCellIdx] = data.reservoirIdx;
}
