import os

# with open(os.path.dirname(__file__) + '\\ReSTIR_FG_Kitchen.py') as file:
# with open(os.path.dirname(__file__) + '\\ReSTIR_FG_VeachAjar.py') as file:
with open(os.path.dirname(__file__) + '\\ReSTIR_FG_PinkRoom.py') as file:
    exec(file.read())
