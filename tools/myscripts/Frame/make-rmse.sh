#!/bin/bash

# 函數：檢查傳入的字串陣列中是否包含非空字串
has_non_empty()
{
    for element in "$@"; do
        if [[ -n "$element" ]]; then    # 檢查是否為非空字串
            return 0                    # 如果有一個符合條件，返回成功
        fi
    done
    return 1                            # 如果沒有任何符合條件，返回失敗
}

# 檢查是否安裝了 ImageMagick
if ! command -v magick.exe &>/dev/null; then
    echo "ERROR! ImageMagick (magick.exe) is not installed." >&2
    exit 1
fi

# 引入配置檔
CONFIG_FILE="config.sh"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR! Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

# 從來源資料夾複製圖檔
if [[ "$NEED_TO_COPY_IMAGES" == true ]]; then
    # 檢查所有資料夾是否存在且不為空
    for method in "${METHODS[@]}"; do
        if [[ ! -d "$SOURCE_DIR/$method" ]] || [[ -z "$(ls -A "$SOURCE_DIR/$method" 2>/dev/null)" ]]; then
            echo "ERROR! Folder $SOURCE_DIR/$method does not exist or is empty." >&2
            exit 1
        fi
    done
    # 複製圖檔
    for method in "${METHODS[@]}"; do
        printf -v src "$SOURCE_DIR/$method/$IMAGE_PREFIX%d.png" "$IMAGE_ID"
        printf -v dest "$method.png"
        cp "$src" "$dest"
    done
fi

# 確保輸出資料夾存在
mkdir -p "$OUTPUT_FOLDER"

# 檢查渲染時間檔案是否存在，如果存在，將在最終圖片中填入渲染時間資訊
if [[ -f "$RENDER_TIME_FILE" ]]; then
    has_render_time=true
    cp "$RENDER_TIME_FILE" "$OUTPUT_FOLDER/$RENDER_TIME_FILE"
else
    has_render_time=false
fi

# 檢查所需檔案是否存在
for method in "${METHODS[@]}"; do
    if [[ ! -f "$method.png" ]]; then
        echo "ERROR! File $method.png does not exist." >&2
        exit 1
    fi
done

# 複製所需檔案到輸出資料夾
cp "$REFERENCE_NAME.png" "$OUTPUT_FOLDER/marked-$REFERENCE_NAME.png"

#--------------------
# 裁剪小圖片：
#   1) 取得裁剪參數
#   2) 執行裁剪
#--------------------
for idx in "${!PREFIXES[@]}"; do
    prefix=${PREFIXES[$idx]}        # 取得對應的前綴
    # 取得對應的裁剪參數
    crop_param=(${SUBIMAGE_CROP_PARAMS[$idx]})
    crop_width=${crop_param[0]}     # 寬度
    crop_height=${crop_param[1]}    # 高度
    crop_offset_x=${crop_param[2]}  # 偏移 X
    crop_offset_y=${crop_param[3]}  # 偏移 Y
    for method in "${METHODS[@]}"; do
        magick.exe "$method.png" \
            -crop "${crop_width}x${crop_height}+${crop_offset_x}+${crop_offset_y}" +repage \
            "$OUTPUT_FOLDER/$prefix-$method.png" || exit 1
    done
done

# 切換到輸出目錄，如果失敗則退出腳本
cd "$OUTPUT_FOLDER" || exit 1

#---------------------------------------
# 在主場景圖片中標記小圖片的裁剪區域：
#   1) 取得裁剪參數
#   2) 計算矩形區域的定位點
#   3) 繪製矩形
#---------------------------------------
for idx in "${!PREFIXES[@]}"; do
    color=${COLORS[$idx]}           # 取得對應的顏色
    prefix=${PREFIXES[$idx]}        # 取得對應的前綴
    # 取得對應的裁剪參數
    crop_param=(${SUBIMAGE_CROP_PARAMS[$idx]})
    crop_width=${crop_param[0]}     # 寬度
    crop_height=${crop_param[1]}    # 高度
    crop_offset_x=${crop_param[2]}  # 偏移 X
    crop_offset_y=${crop_param[3]}  # 偏移 Y
    # 計算矩形區域的定位點
    top_left_x="$crop_offset_x"     # 左上角 X 座標
    top_left_y="$crop_offset_y"     # 左上角 Y 座標
    bottom_right_x=$((crop_offset_x + crop_width))  # 右下角 X 座標
    bottom_right_y=$((crop_offset_y + crop_height)) # 右下角 Y 座標
    # 繪製矩形
    magick.exe "marked-$REFERENCE_NAME.png" \
        -fill none -stroke "$color" -strokewidth "$STROKE_WIDTH" \
        -draw "rectangle $top_left_x,$top_left_y $bottom_right_x,$bottom_right_y" \
        "marked-$REFERENCE_NAME.png" || exit 1
done

# 先清空要寫入 RMSE 值的檔案
> "$RMSE_OUTPUT_FILE"

#---------------------
# 編輯小圖片：
#   1) 調整圖片大小
#   2) 填入 RMSE 值
#   3) 繪製邊框
#---------------------
for idx in "${!PREFIXES[@]}"; do
    color=${COLORS[$idx]}           # 取得對應的顏色
    prefix=${PREFIXES[$idx]}        # 取得對應的前綴
    echo "" >> "$RMSE_OUTPUT_FILE"  # 換行
    for method in "${METHODS[@]}"; do
        # 調整圖片大小
        magick.exe "$prefix-$method.png" \
            -resize "$RESIZED_DIMENSIONS"\! \
            "$prefix-$method-resized.png" || exit 1
        if [[ "$method" != "$REFERENCE_NAME" ]]; then
            # 計算 RMSE 值
            compare_output=$(magick.exe compare -metric RMSE "$prefix-$REFERENCE_NAME.png" "$prefix-$method.png" null: 2>&1)
            compare_status=$?  # 獲取 magick.exe 的退出狀態碼
            # 如果 compare 命令失敗，退出腳本並輸出錯誤訊息
            if [[ $compare_status -ne 0 && $compare_status -ne 1 ]]; then
                # 狀態碼為 0：完全相同的圖片，compare 成功執行。
                # 狀態碼為 1：圖片不同，但 RMSE 值正確計算，compare 成功執行。
                # 只有當狀態碼 既不是 0 也不是 1 時，才視為命令執行失敗。
                echo "ERROR! Failed to compare $prefix-$REFERENCE_NAME.png with $prefix-$method.png" >&2
                echo "$compare_output" >&2  # 顯示錯誤訊息詳細內容
                exit 1
            fi
            # 提取 RMSE 值
            rmse=$(echo "$compare_output" | awk -F '[()]' '{printf "%.3f\n", $2}')
            echo "$prefix-$method.png: $rmse" | tee -a "$RMSE_OUTPUT_FILE"
            # 填入 RMSE 值
            magick.exe "$prefix-$method-resized.png" \
                -fill white -undercolor '#00000060' -gravity South -font "$FONT_NAME" \
                -pointsize "$FONT_SIZE" -annotate +0+0 "RMSE: $rmse" \
                "$prefix-$method-resized.png"  || exit 1
                # -fill white             : 文字顏色
                # -undercolor '#00000050' : 調整背景透明度 (#00000000:全透明)
                # -gravity South          : 垂直靠下並水平置中
                # -pointsize "$FONT_SIZE" : 文字大小
                # -annotate +0+10         : 向上偏移 10 像素
        fi
        # 繪製邊框
        magick.exe "$prefix-$method-resized.png" \
            -bordercolor "$color" -border "$BORDER_WIDTH"x"$BORDER_WIDTH" \
            "$prefix-$method-resized.png" || exit 1
    done
done
echo "RMSE file created: $RMSE_OUTPUT_FILE"

#---------------------
# 編輯第一列小圖片：
#   1) 添加白色區域
#   2) 填入欄位標題
#---------------------
for idx in "${!METHODS[@]}"; do
    method=${METHODS[$idx]}         # 根據索引取得檔案名稱
    title=${TITLES[$idx]}           # 根據索引取得欄位主標題
    subtitle=${SUBTITLES[$idx]}     # 根據索引取得欄位副標題
    # 在圖片上方新增白色區域以填入標題
    magick.exe "${PREFIXES[0]}-$method-resized.png" \
        -gravity North -background white -splice 0x"$TITLE_BAR_HEIGHT" \
        "${PREFIXES[0]}-$method-resized.png" || exit 1
    # 根據是否有副標題來設定主標題的偏移量
    if [[ -n "$subtitle" ]]; then   # 檢查副標題是否為非空字串
        title_offset=-3             # 有副標題 => 主標題要向上偏移
    else
        title_offset=10             # 無副標題 => 主標題要向下偏移
    fi
    # 填入欄位主標題
    magick.exe "${PREFIXES[0]}-$method-resized.png" \
        -fill black -gravity North -font "$FONT_NAME" \
        -pointsize "$FONT_SIZE" -annotate +0+"$title_offset" "$title" \
        "${PREFIXES[0]}-$method-resized.png" || exit 1
        # -gravity North          : 垂直靠上並水平置中
        # -pointsize "$FONT_SIZE" : 文字大小
        # -annotate +0+10         : 向下偏移 10 像素
    # 填入欄位副標題
    magick.exe "${PREFIXES[0]}-$method-resized.png" \
        -fill black -gravity North -font "$SUB_FONT_NAME" \
        -pointsize "$SUB_FONT_SIZE" -annotate +0+15 "$subtitle" \
        "${PREFIXES[0]}-$method-resized.png" || exit 1
done

#-----------------------
# 編輯最後一列小圖片：
#   1) 添加白色區域
#   2) 讀取渲染時間
#   3) 填入渲染時間
#-----------------------
if [[ "$has_render_time" == true ]]; then
    for idx in "${!METHODS[@]}"; do
        method=${METHODS[$idx]}             # 根據索引取得檔案名稱
        # 在圖片下方新增白色區域以填入標題
        magick.exe "${PREFIXES[-1]}-$method-resized.png" \
            -gravity South -background white -splice 0x"$TIME_BAR_HEIGHT" \
            "${PREFIXES[-1]}-$method-resized.png" || exit 1
        if [[ "$method" == "$REFERENCE_NAME" ]]; then
            continue
        fi
        # 讀取渲染時間
        render_time=$(awk -F '[[:space:]]*:[[:space:]]*' -v method="$method" '$1 == method {print $2}' "$RENDER_TIME_FILE")
        render_time=${render_time:-"N/A"}  # 若為空值，設為 "N/A"
        # 填入渲染時間
        magick.exe "${PREFIXES[-1]}-$method-resized.png" \
            -fill black -gravity South -font "$FONT_NAME" \
            -pointsize "$FONT_SIZE" -annotate +0+10 "$render_time" \
            "${PREFIXES[-1]}-$method-resized.png" || exit 1
            # -gravity South          : 垂直靠下並水平置中
            # -pointsize "$FONT_SIZE" : 文字大小
            # -annotate +0+10         : 向上偏移 10 像素
    done
fi

#------------------------------
# 繪製小圖片的 RMSE 比較表格：
#   1) 構建圖片清單
#   2) 繪製小圖片的表格
#------------------------------
# 構建圖片清單
image_list=()  # 初始化圖片清單變數
for idx in "${!PREFIXES[@]}"; do
    prefix=${PREFIXES[$idx]}  # 取得對應的前綴
    for method in "${METHODS[@]}"; do
        # 將檔名加入清單
        image_list+=("$prefix-$method-resized.png")
    done
done
# 繪製小圖片的表格
magick.exe montage "${image_list[@]}" \
    -tile "$GRID_ROWSx$GRID_COLS" -geometry +"$TILE_SPACING"+"$TILE_SPACING" \
    -background white -border 0 \
    "rmse-grid.png" || exit 1

#--------------------------
# 編輯主場景圖片：
#   1) 取得裁剪參數
#   2) 執行裁剪
#   3) 調整主場景圖片大小
#   4) 填入欄位標題
#   5) 填入渲染資訊
#--------------------------
# 組合裁剪參數
crop_params="${CROP_SIZE[0]}x${CROP_SIZE[1]}+${CROP_OFFSET[0]}+${CROP_OFFSET[1]}"
# 執行裁剪命令
magick.exe "marked-$REFERENCE_NAME.png" \
    -crop "$crop_params" +repage \
    "marked-$REFERENCE_NAME-resized.png" || exit 1
# 取得小圖片表格的高度
grid_height=$(magick.exe identify -format "%h" "rmse-grid.png")
# 計算目標高度
target_height=$((grid_height - TITLE_BAR_HEIGHT - 2 * TILE_SPACING))
# 若有時間欄要額外扣掉時間欄的高度
if [[ "$has_render_time" == true ]]; then
    target_height=$((target_height - TIME_BAR_HEIGHT))
fi
# 將高度調整為計算出的目標高度
magick.exe "marked-$REFERENCE_NAME-resized.png" \
    -resize x"$target_height" \
    "marked-$REFERENCE_NAME-resized.png" || exit 1
# 在圖片上方新增白色區域以填入標題
magick.exe "marked-$REFERENCE_NAME-resized.png" \
    -gravity North -background white -splice 0x"$TITLE_BAR_HEIGHT" \
    "marked-$REFERENCE_NAME-resized.png" || exit 1
# 填入欄位標題
magick.exe "marked-$REFERENCE_NAME-resized.png" \
    -fill black -gravity North -font "$FONT_NAME" \
    -pointsize "$FONT_SIZE" -annotate +0+10 "$SCENE_NAME" \
    "marked-$REFERENCE_NAME-resized.png" || exit 1
    # -gravity North          : 垂直靠上並水平置中
    # -pointsize "$FONT_SIZE" : 文字大小
    # -annotate +0+10         : 向下偏移 10 像素
# 若有時間欄就在圖片下方新增白色區域以填入渲染資訊
if [[ "$has_render_time" == true ]]; then
    # 新增白色區域
    magick.exe "marked-$REFERENCE_NAME-resized.png" \
        -gravity South -background white -splice 0x"$TIME_BAR_HEIGHT" \
        "marked-$REFERENCE_NAME-resized.png" || exit 1
    # 讀取渲染資訊 (第一行)
    render_info=$(head -n 1 "$RENDER_TIME_FILE")
    # 填入渲染資訊
    magick.exe "marked-$REFERENCE_NAME-resized.png" \
        -fill black -gravity South -font "$FONT_NAME" \
        -pointsize "$FONT_SIZE" -annotate +0+10 "$render_info" \
        "marked-$REFERENCE_NAME-resized.png" || exit 1
        # -gravity South          : 垂直靠下並水平置中
        # -pointsize "$FONT_SIZE" : 文字大小
        # -annotate +0+10         : 向上偏移 10 像素
fi
# 添加邊框
magick.exe "marked-$REFERENCE_NAME-resized.png" \
    -bordercolor white -border "$TILE_SPACING"x"$TILE_SPACING" \
    "marked-$REFERENCE_NAME-resized.png" || exit 1

#---------------------------------
# 合併主場景圖片和 RMSE 網格圖片
#---------------------------------
magick.exe "marked-$REFERENCE_NAME-resized.png" "rmse-grid.png" +append "$OUTPUT_IMAGE" || exit 1

# 刪除臨時檔案以釋放空間
rm -f *-resized.png "$RENDER_TIME_FILE" "rmse-grid.png"

echo "RMSE image created: $OUTPUT_IMAGE"
echo -e "✅ 所有圖片處理完成！"
