# 流程控制
GENERATE_INDIVIDUAL_VIDEOS=false
GENERATE_MERGE_IMAGES=true
GENERATE_MERGE_VIDEO=true
ONE_FRAME_TEST=false
SHOW_TITLES=true

# 檔案與資料夾名稱
OUTPUT_FOLDER="Output"                  # 輸出資料夾
MERGE_OUTPUT="Merge"                    # 合併資料夾
IMAGE_PREFIX="Mogwai.ToneMapper.dst."   # 圖檔名稱前綴

# 圖片參數
IMAGE_START_ID=179              # 圖檔起始編號
CROP_SIZE=(420 800)             # 裁剪區域的寬度和高度
CROP_OFFSET=(480 0)             # 裁剪區域的左上角座標 (X 和 Y)
TITLE_OFFSET=700                # 主標題的向下偏移量
SEPARATOR_WIDTH=3               # 分隔線寬度
SEPARATOR_COLOR="rgb(0,0,0)"    # 分隔線顏色

# 影片參數
VIDEO_INPUT_FPS=6               # 原始圖片序列的幀率（每秒輸入幾張圖片）
VIDEO_OUTPUT_FPS=30             # 生成影片的目標幀率（每秒幀數）

# 目錄清單對應各種渲染方法
METHODS=(
    "ReSTIR-GI"
    "ReSTIR-FG"
    "Ours-4-spatial-samples"
    "Ours-4-spatial-samples-trial"
)

# 主標題
TITLES=("ReSTIR GI"
        "ReSTIR FG"
        "Ours"
        "Ours"
)

# 副標題
SUBTITLES=("" "" "" "(new trial)")

# 字體和格式設定
FONT_NAME="Arial-Bold"      # 主標題字體
FONT_SIZE=55                # 主標題字體大小
FONT_FILL="white"           # 主標題字體顏色
FONT_STROKE="black"         # 主標題邊框顏色
FONT_STROKEWIDTH=2          # 主標題邊框寬度
SUB_FONT_NAME="Arial-Bold"  # 副標題字體
SUB_FONT_SIZE=33            # 副標題字體大小
SUB_FONT_FILL="white"       # 副標題字體顏色
SUB_FONT_STROKE="black"     # 副標題邊框顏色
SUB_FONT_STROKEWIDTH=2      # 副標題邊框寬度
