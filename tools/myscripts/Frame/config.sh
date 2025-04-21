# 從來源資料夾複製圖檔
NEED_TO_COPY_IMAGES=true                # 是否需要執行複製
SOURCE_DIR="../Animations"              # 來源資料夾
IMAGE_PREFIX="Mogwai.ToneMapper.dst."   # 圖檔名稱前綴
IMAGE_ID=186                            # 複製的圖檔編號

# 場景名稱
SCENE_NAME="Kitchen"

# 檔案與資料夾名稱
OUTPUT_FOLDER="Output"              # 輸出資料夾
REFERENCE_NAME="Reference"          # Reference 圖檔主檔名
RENDER_TIME_FILE="render_time.txt"  # 儲存渲染時間的檔案
OUTPUT_IMAGE="rmse_output.png"      # 最終輸出圖檔名稱
RMSE_OUTPUT_FILE="rmse_output.txt"  # 寫入 RMSE 值的檔案

# 渲染方法的檔名清單 (對應生成的圖片檔案前綴)
METHODS=(
    "ReSTIR-GI"
    "ReSTIR-FG"
    "Ours-4-spatial-samples"
    "Ours-4-spatial-samples-trial"
    "$REFERENCE_NAME"
)

# 欄位主標題
TITLES=("ReSTIR GI"
        "ReSTIR FG"
        "Ours"
        "Ours"
        "$REFERENCE_NAME"
)

# 欄位副標題
SUBTITLES=("" "" "" "(new trial)" "")

# 圖檔前綴
PREFIXES=("img1" "img2")

# 小圖的裁剪參數："寬度 高度 偏移X 偏移Y"
SUBIMAGE_CROP_PARAMS=(
    "100 100 640 0"
    "64  64  588 352"
)

# 主場景圖片參數
CROP_SIZE=(800 800)     # 裁剪區域的寬度和高度
CROP_OFFSET=(261 0)     # 裁剪區域的左上角座標 (X 和 Y)
STROKE_WIDTH=5          # 標記小圖片區域的矩形線條寬度

# 邊框顏色
COLORS=(
    "rgb(254, 191, 0)"    # 橘黃色
    "rgb(1, 112, 191)"    # 靛藍色（Indigo / Deep Blue）
    "rgb(50, 191, 50)"    # 綠色（Green）
    "rgb(191, 50, 50)"    # 紅色（Red）
    "rgb(255, 69, 0)"     # 橘紅色（Red-Orange）
    "rgb(255, 165, 0)"    # 橙色（Orange）
    "rgb(75, 0, 130)"     # 靛藍色（Indigo）
    "rgb(0, 255, 255)"    # 青色（Cyan）
    "rgb(255, 20, 147)"   # 深粉紅色（Deep Pink）
    "rgb(0, 0, 0)"        # 黑色（Black，適合非常明亮的背景）
    "rgb(255, 255, 255)"  # 白色（White，適合非常深色的背景）
    "rgb(0, 128, 0)"      # 深綠色（Dark Green）
    "rgb(0, 0, 255)"      # 藍色（Blue）
    "rgb(255, 255, 0)"    # 黃色（Yellow）
)

# 小圖片和表格參數
RESIZED_DIMENSIONS="100x100"    # 小圖的大小
BORDER_WIDTH="4"                # 小圖的邊框寬度
TITLE_BAR_HEIGHT="30"           # 標題欄的高度
TIME_BAR_HEIGHT="30"            # 時間欄的高度
TILE_SPACING="2"                # 小圖之間的水平和垂直間距 (實際間距要乘以 2)
GRID_ROWS=${#PREFIXES[@]}       # 表格列數
GRID_COLS=${#METHODS[@]}        # 表格行數

# 字體和格式設定
FONT_NAME="Arial-Bold"  # 主標題字體
FONT_SIZE=16            # 主標題字體大小
SUB_FONT_NAME="Arial"   # 副標題字體
SUB_FONT_SIZE=12        # 副標題字體大小
