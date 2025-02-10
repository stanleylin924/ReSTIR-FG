# Graphs
from pathlib import WindowsPath, PosixPath
from falcor import *
import sys

# Add the path of the helper script file to the system path
sys.path.append('D:/3D_Scene/script')
import framecapture

def render_graph_RTXDI():
    g = RenderGraph('RTXDI')
    g.create_pass('AccumulatePass', 'AccumulatePass', {'enabled': False, 'outputSize': 'Default', 'autoReset': True, 'precisionMode': 'Single', 'maxFrameCount': 0, 'overflowMode': 'Stop'})
    g.create_pass('ToneMapper', 'ToneMapper', {'outputSize': 'Default', 'useSceneMetadata': True, 'exposureCompensation': 0.0, 'autoExposure': False, 'filmSpeed': 100.0, 'whiteBalance': False, 'whitePoint': 6500.0, 'operator': 'Linear', 'clamp': True, 'whiteMaxLuminance': 1.0, 'whiteScale': 11.199999809265137, 'fNumber': 1.0, 'shutter': 1.0, 'exposureMode': 'AperturePriority'})
    g.create_pass('VBufferRT', 'VBufferRT', {'outputSize': 'Default', 'samplePattern': 'Center', 'sampleCount': 16, 'useAlphaTest': True, 'adjustShadingNormals': True, 'forceCullMode': False, 'cull': 'Back', 'useTraceRayInline': False, 'useDOF': False})
    g.create_pass('RTXDIPass', 'RTXDIPass')
    g.add_edge('AccumulatePass.output', 'ToneMapper.src')
    g.add_edge('VBufferRT.mvec', 'RTXDIPass.mvec')
    g.add_edge('VBufferRT.vbuffer', 'RTXDIPass.vbuffer')
    g.add_edge('RTXDIPass.color', 'AccumulatePass.input')
    g.mark_output('ToneMapper.dst')
    g.mark_output('AccumulatePass.output')
    return g
m.addGraph(render_graph_RTXDI())

# Scene
m.loadScene('D:/3D_Scene/Others/pink_room/pink_room_v1.2.pyscene')
m.scene.renderSettings = SceneRenderSettings(useEnvLight=True, useAnalyticLights=True, useEmissiveLights=True, useGridVolumes=True, diffuseAlbedoMultiplier=1)
m.scene.cameraSpeed = 1.0

# Window Configuration
m.resizeFrameBuffer(1280, 800)
m.ui = True

# Clock Settings
m.clock.time = 0
m.clock.framerate = 30
# If framerate is not zero, you can use the frame property to set the start frame
# m.clock.frame = 0

# Frame Capture
m.frameCapture.outputDir = 'D:/Temp/FrameCapture'
m.frameCapture.baseFilename = 'Mogwai'

# framecapture.capture_cameras(m, 30)
# framecapture.capture_frames(m, 0, 1000)
