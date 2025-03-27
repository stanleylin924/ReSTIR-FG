import os

file_name = "ReSTIR_FG_Kitchen.py"
# file_name = "ReSTIR_FG_VeachAjar.py"
# file_name = "ReSTIR_FG_Staircase.py"
# file_name = "ReSTIR_FG_PinkRoom.py"
# file_name = "..\\scripts\\PathTracer.py"

file_path = os.path.join(os.path.dirname(__file__), file_name)
with open(file_path, 'r', encoding='utf-8') as file:
    exec(file.read())
