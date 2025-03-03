# Graphs
from pathlib import WindowsPath, PosixPath
from falcor import *
import sys

# Add the path of the helper script file to the system path
sys.path.append('D:/3D_Scene/script')
import framecapture

def render_graph_ReSTIR_FG():
    g = RenderGraph('ReSTIR_FG')
    g.create_pass('AccumulatePass', 'AccumulatePass', {'enabled': False, 'outputSize': 'Default', 'autoReset': True, 'precisionMode': 'Single', 'maxFrameCount': 0, 'overflowMode': 'Stop'})
    g.create_pass('ToneMapper', 'ToneMapper', {'outputSize': 'Default', 'useSceneMetadata': True, 'exposureCompensation': 0.0, 'autoExposure': False, 'filmSpeed': 100.0, 'whiteBalance': False, 'whitePoint': 6500.0, 'operator': 'Linear', 'clamp': True, 'whiteMaxLuminance': 1.0, 'whiteScale': 11.199999809265137, 'fNumber': 1.0, 'shutter': 1.0, 'exposureMode': 'AperturePriority'})
    g.create_pass('VBufferRT', 'VBufferRT', {'outputSize': 'Default', 'samplePattern': 'Center', 'sampleCount': 16, 'useAlphaTest': True, 'adjustShadingNormals': True, 'forceCullMode': False, 'cull': 'Back', 'useTraceRayInline': False, 'useDOF': False})
    g.create_pass('ReSTIR_FG', 'ReSTIR_FG', {'PhotonBufferSizeGlobal': 800000, 'PhotonBufferSizeCaustic': 400000, 'AnalyticEmissiveRatio': 0.3499999940395355, 'PhotonBouncesGlobal': 10, 'PhotonBouncesCaustic': 10, 'PhotonRadiusGlobal': 0.01600000075995922, 'PhotonRadiusCaustic': 0.004000000189989805, 'EnableStochCollect': True, 'StochCollectK': 3, 'EnablePhotonCullingGlobal': True, 'EnablePhotonCullingCaustic': True, 'CullingRadius': 0.10000000149011612, 'CullingBits': 20, 'CausticCollectionMode': 3, 'CausticResamplingMode': 2, 'EnableDynamicDispatch': False, 'NumDispatchedPhotons': 1199616})
    g.add_edge('AccumulatePass.output', 'ToneMapper.src')
    g.add_edge('VBufferRT.mvec', 'ReSTIR_FG.mvec')
    g.add_edge('VBufferRT.vbuffer', 'ReSTIR_FG.vbuffer')
    g.add_edge('ReSTIR_FG.color', 'AccumulatePass.input')
    # g.add_edge('ReSTIR_FG.disocclusion', 'AccumulatePass.input')  # Profiler: 觀察 disocclusion 像素個數
    g.mark_output('ToneMapper.dst')
    return g
m.addGraph(render_graph_ReSTIR_FG())

# Scene
m.loadScene('D:/3D_Scene/ReSTIR-FG/Kitchen_ReSTIRFG/KitchenReSTIRFG_v1.3.pyscene')
m.scene.renderSettings = SceneRenderSettings(useEnvLight=True, useAnalyticLights=True, useEmissiveLights=True, useGridVolumes=True, diffuseAlbedoMultiplier=1)
m.scene.cameraSpeed = 1.0

# Window Configuration
m.resizeFrameBuffer(1280, 800)
# m.resizeFrameBuffer(1000, 800)  # Profiler: 統計 disocclusion 像素個數 vs. 處理耗時，以 1000 為單位便於統計
m.ui = True

# Clock Settings
m.clock.time = 0
m.clock.framerate = 30
# If framerate is not zero, you can use the frame property to set the start frame
# m.clock.frame = 0
# m.clock.exitFrame = 250

# Frame Capture
m.frameCapture.outputDir = 'D:/Temp/FrameCapture'
m.frameCapture.baseFilename = 'Mogwai'

# framecapture.capture_cameras(m, 30)
framecapture.capture_frames(m, 179, 229)
# m.timingCapture.captureFrameTime("D:/Temp/FrameCapture/timecapture.csv")

# Profiler: Disocclusion 效能分析
meanFrameTime = 0
meanTracePathTime = 0
meanResamplingTime = 0
frameCount = 0  # 計算有效幀數
m.profiler.enabled = True
for frame in range(250):
    m.renderFrame()
    # Profiler: 打印 183~196 幀的 Disocclusion 效能數據
    if m.clock.frame in range(183, 197):
        print(f"Frame ID: {m.clock.frame}", flush=True)
        cputime = m.profiler.events["/onFrameRender/cpu_time"]["value"]
        gputime = m.profiler.events["/onFrameRender/gpu_time"]["value"]
        print(f"Frame time: {cputime}/{gputime} ms")
        cputime = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/TracePathGIDisocclusion/cpu_time"]["value"]
        gputime = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/TracePathGIDisocclusion/gpu_time"]["value"]
        print(f"TracePathGI time: {cputime}/{gputime} ms")
        cputime = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/SpatiotemporalResamplingDisocclusion/cpu_time"]["value"]
        gputime = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/SpatiotemporalResamplingDisocclusion/gpu_time"]["value"]
        print(f"SpatiotemporalResampling time: {cputime}/{gputime} ms")
    # Profiler: 計算 200 幀的 Disocclusion 統計數據
    """
    if m.clock.frame in range(10, 210):  # 跳過前面 10 幀 (warm up 時間可能失真)
        gputime1 = m.profiler.events.get("/onFrameRender/gpu_time", {}).get("value", None)
        gputime2 = m.profiler.events.get("/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/TracePathGIDisocclusion/gpu_time", {}).get("value", None)
        gputime3 = m.profiler.events.get("/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/SpatiotemporalResamplingDisocclusion/gpu_time", {}).get("value", None)
        if all(t is not None for t in [gputime1, gputime2, gputime3]):  # 確保所有數據都可用
            meanFrameTime += gputime1
            meanTracePathTime += gputime2
            meanResamplingTime += gputime3
            frameCount += 1  # 只有有效 GPU 時間才計數
        else:
            print(f"Warning: GPU time not available for frame {m.clock.frame}")
    """

m.profiler.enabled = False

# Profiler: 打印 200 幀的 Disocclusion 統計數據
"""
if frameCount > 0:
    meanFrameTime /= frameCount
    meanTracePathTime /= frameCount
    meanResamplingTime /= frameCount
    print(f"Mean frame time for {frameCount} frames: {meanFrameTime} ms")  # 平均每幀耗時
    print(f"Mean trace path time for {frameCount} frames: {meanTracePathTime} ms")  # 平均 trace path (inital sampling) 階段耗時 for Disocclusion 處理
    print(f"Mean resampling time for {frameCount} frames: {meanResamplingTime} ms") # 平均 resampling 階段耗時 for Disocclusion 處理
else:
    print("No valid frame times captured.")
"""
