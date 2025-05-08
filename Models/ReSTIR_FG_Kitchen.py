# Graphs
from pathlib import WindowsPath, PosixPath, Path
from falcor import *
import sys, shutil

# Add the path of the helper script file to the system path
sys.path.append('D:/3D_Scene/script')
import framecapture

ENABLE_CAPTURE_FRAME = True
ENABLE_DISOCCLUSION_OUTPUT = False
ENABLE_AUTO_EXIT = False
ENABLE_PROFILER = False
PROFILE_MEAN_FRAME_TIME = True
PROFILE_DISOCCLUSION_TIME = False
PROFILE_SINGLE_FRAME = False
ENABLE_CAMERA_ORIENTATION = False
DISOCCLUSION_TESTCASE = 1

ENABLE_WORLDSPACE = False
RENDER_MODE = 'ReSTIRGI'  # FinalGather, ReSTIRFG, ReSTIRGI

# 檢測單幀數據時，關閉截圖以避免影響分析數據
if ENABLE_PROFILER and PROFILE_SINGLE_FRAME:
    ENABLE_CAPTURE_FRAME = False

# 使用環境變數傳遞參數到 pyscene 文件
os.environ['DISOCCLUSION_TESTCASE'] = str(DISOCCLUSION_TESTCASE)

# 動態設定名稱
restir_fg = 'WorldSpace_ReSTIR_FG' if ENABLE_WORLDSPACE else 'ReSTIR_FG'

def render_graph_ReSTIR_FG():
    g = RenderGraph(restir_fg)
    g.create_pass('AccumulatePass', 'AccumulatePass', {'enabled': False, 'outputSize': 'Default', 'autoReset': True, 'precisionMode': 'Single', 'maxFrameCount': 0, 'overflowMode': 'Stop'})
    g.create_pass('ToneMapper', 'ToneMapper', {'outputSize': 'Default', 'useSceneMetadata': True, 'exposureCompensation': 0.0, 'autoExposure': False, 'filmSpeed': 100.0, 'whiteBalance': False, 'whitePoint': 6500.0, 'operator': 'Linear', 'clamp': True, 'whiteMaxLuminance': 1.0, 'whiteScale': 11.199999809265137, 'fNumber': 1.0, 'shutter': 1.0, 'exposureMode': 'AperturePriority'})
    g.create_pass('VBufferRT', 'VBufferRT', {'outputSize': 'Default', 'samplePattern': 'Center', 'sampleCount': 16, 'useAlphaTest': True, 'adjustShadingNormals': True, 'forceCullMode': False, 'cull': 'Back', 'useTraceRayInline': False, 'useDOF': False})
    g.create_pass(restir_fg, restir_fg, {'RenderMode': RENDER_MODE, 'PhotonBufferSizeGlobal': 800000, 'PhotonBufferSizeCaustic': 400000, 'AnalyticEmissiveRatio': 0.3499999940395355, 'PhotonBouncesGlobal': 10, 'PhotonBouncesCaustic': 10, 'PhotonRadiusGlobal': 0.01600000075995922, 'PhotonRadiusCaustic': 0.004000000189989805, 'EnableStochCollect': True, 'StochCollectK': 3, 'EnablePhotonCullingGlobal': True, 'EnablePhotonCullingCaustic': True, 'CullingRadius': 0.10000000149011612, 'CullingBits': 20, 'CausticCollectionMode': 3, 'CausticResamplingMode': 2, 'EnableDynamicDispatch': False, 'NumDispatchedPhotons': 1199616})
    g.add_edge('AccumulatePass.output', 'ToneMapper.src')
    g.add_edge('VBufferRT.mvec', f'{restir_fg}.mvec')
    g.add_edge('VBufferRT.vbuffer', f'{restir_fg}.vbuffer')
    if ENABLE_DISOCCLUSION_OUTPUT:
        g.add_edge(f'{restir_fg}.disocclusion', 'AccumulatePass.input')  # Profiler: 觀察 disocclusion 像素個數
    else:
        g.add_edge(f'{restir_fg}.color', 'AccumulatePass.input')
    g.mark_output('ToneMapper.dst')
    return g
m.addGraph(render_graph_ReSTIR_FG())

# Scene
m.loadScene('D:/3D_Scene/ReSTIR-FG/Kitchen_ReSTIRFG/Kitchen_Disocclusion_v1.4.pyscene')
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

# Frame Capture
if DISOCCLUSION_TESTCASE == 1:
    captureStart = 179
    captureEnd = 229
elif DISOCCLUSION_TESTCASE == 2:
    captureStart = 116
    captureEnd = 153
elif DISOCCLUSION_TESTCASE == 3:
    captureStart = 116
    captureEnd = 150
elif DISOCCLUSION_TESTCASE == 4:
    captureStart = 116
    captureEnd = 144
elif DISOCCLUSION_TESTCASE == 5:
    captureStart = 175
    captureEnd = 265
    # Pause to animate scene in order to generate reference picture with path tracer
    if False:
        for frame in range(captureEnd+1):
            m.renderFrame()
            if m.clock.frame == 248:
                m.clock.pause()
else:
    captureStart = 0
    captureEnd = 500
# 指定輸出資料夾
outputDir = Path('D:/Temp/FrameCapture')
# 如果資料夾存在，先刪除它
if outputDir.exists() and outputDir.is_dir():
    shutil.rmtree(outputDir)
# 重新建立資料夾
outputDir.mkdir(parents=True, exist_ok=True)
# 配置 frameCapture 的 outputDir
m.frameCapture.outputDir = str(outputDir)
m.frameCapture.baseFilename = 'Mogwai'
if ENABLE_CAPTURE_FRAME:
    framecapture.capture_frames(m, captureStart, captureEnd)
if ENABLE_AUTO_EXIT:
    m.clock.exitFrame = captureEnd + 5

# Camera: 打印相機的方位
if ENABLE_CAMERA_ORIENTATION:
    m.clock.frame = 0  # 從第 0 幀開始
    for frame in range(captureEnd+1):
        m.renderFrame()
        if m.clock.frame in range(captureStart, captureEnd+1):
            print(f"INFO: frame #{m.clock.frame}:")
            print(f"  camera position: {m.scene.camera.position}")
            print(f"    camera target: {m.scene.camera.target}")
            print(f"        camera up: {m.scene.camera.up}")

# Profiler: Disocclusion 效能分析
if ENABLE_PROFILER:
    frameStart = captureEnd + 10  # 跳過前面 warm up 幀與截圖幀以避免影響分析數據
    frameEnd = frameStart + 1000  # 統計 1000 幀
    if ENABLE_AUTO_EXIT:
        m.clock.exitFrame = frameEnd + 5
    meanFrameTime = 0
    meanFrameTimeFrames = 0
    meanDisocclusionTime = {'tracePath': 0, 'resampling': 0}
    meanDisocclusionTimeFrames = 0
    m.clock.frame = 0  # 從第 0 幀開始
    m.profiler.enabled = True
    for frame in range(frameEnd):
        m.renderFrame()
        # 檢測平均幀時
        if PROFILE_MEAN_FRAME_TIME:
            if m.clock.frame in range(frameStart, frameEnd):
                time = m.profiler.events.get("/onFrameRender/gpu_time", {}).get("value", None)
                if time is not None:  # 確保數據可用
                    meanFrameTime += time
                    meanFrameTimeFrames += 1  # 計算有效幀數
                else:
                    print(f"WARNING: frame time not available for frame {m.clock.frame}")
        # 檢測 Disocclusion 處理時間
        if PROFILE_DISOCCLUSION_TIME:
            if m.clock.frame in range(frameStart, frameEnd):  # 跳過前面 10 幀 (warm up 時間可能失真)
                time1 = m.profiler.events.get("/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/TracePathGIDisocclusion/gpu_time", {}).get("value", None)
                time2 = m.profiler.events.get("/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/SpatiotemporalResamplingDisocclusion/gpu_time", {}).get("value", None)
                if all(t is not None for t in [time1, time2]):  # 確保所有數據都可用
                    meanDisocclusionTime['tracePath'] += time1
                    meanDisocclusionTime['resampling'] += time2
                    meanDisocclusionTimeFrames += 1  # 計算有效幀數
                else:
                    print(f"WARNING: disocclusion time not available for frame {m.clock.frame}")
        # 檢測單幀
        if PROFILE_SINGLE_FRAME:
            if m.clock.frame in range(captureStart-5, captureEnd+5):
                # frame time = time1
                time1 = m.profiler.events["/onFrameRender/gpu_time"]["value"]
                # disocclusion time = trace path time (time2) + resampling time (time3)
                time2 = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/TracePathGIDisocclusion/gpu_time"]["value"]
                time3 = m.profiler.events["/onFrameRender/RenderGraphExe::execute()/ReSTIR_FG/SpatiotemporalResamplingDisocclusion/gpu_time"]["value"]
                print(f"INFO: frame #{m.clock.frame}: {time1:.2f} ms, {(time2+time3):.2f} ms ({time2:.2f} + {time3:.2f})", flush=True)
    m.profiler.enabled = False
    # 顯示平均幀時
    if PROFILE_MEAN_FRAME_TIME:
        if meanFrameTimeFrames > 0:
            meanFrameTime /= meanFrameTimeFrames
            print(f"INFO: mean frame time for {meanFrameTimeFrames} frames: {meanFrameTime:.2f} ms")
        else:
            print("WARNING: no valid frame times captured.")
    # 顯示 Disocclusion 處理時間: (disocclusion time) = (trace path time) + (resampling time)
    if PROFILE_DISOCCLUSION_TIME:
        if meanDisocclusionTimeFrames > 0:
            meanDisocclusionTime['tracePath'] /= meanDisocclusionTimeFrames
            meanDisocclusionTime['resampling'] /= meanDisocclusionTimeFrames
            totalTime = meanDisocclusionTime['tracePath'] + meanDisocclusionTime['resampling']
            print(f"INFO: mean disocclusion time for {meanDisocclusionTimeFrames} frames: {totalTime:.2f} ms ({meanDisocclusionTime['tracePath']:.2f} + {meanDisocclusionTime['resampling']:.2f})")
        else:
            print("WARNING: no valid disocclusion times captured.")
