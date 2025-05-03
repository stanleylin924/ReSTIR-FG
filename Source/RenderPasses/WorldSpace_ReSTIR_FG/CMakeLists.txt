add_plugin(WorldSpace_ReSTIR_FG)

target_sources(WorldSpace_ReSTIR_FG PRIVATE
	WorldSpace_ReSTIR_FG.cpp
	WorldSpace_ReSTIR_FG.h
	Shader/CausticResamplingPass.cs.slang
	Shader/CollectPhotons.rt.slang
	Shader/DirectAnalytic.cs.slang
	Shader/FinalGatherData.slang
	Shader/FinalShading.cs.slang
	Shader/GenerateFinalGatherSamples.rt.slang
	Shader/GenerateGIPathSamples.rt.slang
	Shader/GeneratePhotons.rt.slang
	Shader/Hash.slang
	Shader/ResamplingPass.cs.slang
	Shader/Reservoir.slang
	Shader/SurfaceDataFG.slang
	Shader/TraceTransmissionDelta.rt.slang	
)

target_copy_shaders(WorldSpace_ReSTIR_FG RenderPasses/WorldSpace_ReSTIR_FG)

target_source_group(WorldSpace_ReSTIR_FG "RenderPasses")
