#!/bin/bash

# 檢查是否安裝了 ImageMagick
if ! command -v magick.exe &>/dev/null; then
    echo "ERROR! ImageMagick (magick.exe) is not installed." >&2
    exit 1
fi

# 檢查是否安裝了 FFmpeg
if ! command -v ffmpeg.exe &>/dev/null; then
    echo "ERROR! FFmpeg (ffmpeg.exe) is not installed." >&2
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

# 確保輸出資料夾存在
mkdir -p "$OUTPUT_FOLDER"

#-------------------------
# 生成各個算法的獨立影片
#-------------------------
if [[ "$GENERATE_INDIVIDUAL_VIDEOS" = true ]]; then
    for method in "${METHODS[@]}"; do
        # 檢查資料夾是否存在且不為空
        if [[ ! -d "$method" ]] || [[ -z "$(ls -A "$method" 2>/dev/null)" ]]; then
            echo "WARNING! Folder $method does not exist or is empty." >&2
            continue
        fi
        # 生成影片
        ffmpeg.exe -loglevel error -framerate "$VIDEO_INPUT_FPS" \
            -start_number "$IMAGE_START_ID" -i "$method/$IMAGE_PREFIX%d.png" \
            -c:v libx264 -pix_fmt yuv420p -r "$VIDEO_OUTPUT_FPS" \
            "$OUTPUT_FOLDER/$method.mp4" -y || exit 1
        echo "Video created: $method.mp4"
    done
fi

#---------------------------
# 生成所有算法的合併圖片：
#   1) 取得裁剪參數
#   2) 執行裁剪
#   3) 填入主標題
#   4) 填入副標題
#   5) 合併圖片
#---------------------------
if [[ "$GENERATE_MERGE_IMAGES" = true ]]; then
    # 檢查所有資料夾是否存在且不為空
    for method in "${METHODS[@]}"; do
        if [[ ! -d "$method" ]] || [[ -z "$(ls -A "$method" 2>/dev/null)" ]]; then
            echo "ERROR! Folder $method does not exist or is empty." >&2
            exit 1
        fi
        # 建立對應的輸出資料夾
        mkdir -p "$OUTPUT_FOLDER/$method"
    done
    # 建立合併圖片的輸出資料夾
    mkdir -p "$OUTPUT_FOLDER/$MERGE_OUTPUT"
    # 設定參數
    files=(${METHODS[0]}/*.png)     # 取得檔案清單
    total=${#files[@]}              # 計算總數
    count=0                         # 已處理的檔案數
    # 設定裁剪區域
    crop_params="${CROP_SIZE[0]}x${CROP_SIZE[1]}+${CROP_OFFSET[0]}+${CROP_OFFSET[1]}"
    for file in "${files[@]}"; do
        filename=$(basename "$file")        # 取得檔名 (不含路徑)
        for idx in "${!METHODS[@]}"; do
            method=${METHODS[$idx]}         # 根據索引取得資料夾名稱
            title=${TITLES[$idx]}           # 根據索引取得主標題
            subtitle=${SUBTITLES[$idx]}     # 根據索引取得副標題
            # 執行裁剪
            magick.exe "$method/$filename" \
                -crop "$crop_params" +repage \
                "$OUTPUT_FOLDER/$method/$filename" || exit 1
            if [[ "$SHOW_TITLES" == true ]]; then
                # 根據是否有副標題來設定主標題的偏移量
                if [[ -n "$subtitle" ]]; then   # 檢查副標題是否為非空字串
                    title_offset=$((TITLE_OFFSET - SUB_FONT_SIZE / 4))  # 有副標題 => 主標題要向上偏移
                else
                    title_offset="$TITLE_OFFSET"     # 無副標題 => 主標題維持原始偏移
                fi
                # 設定副標題的偏移量
                subtitle_offset=$((title_offset + FONT_SIZE))
                # 填入主標題
                magick.exe "$OUTPUT_FOLDER/$method/$filename" \
                    -fill "$FONT_FILL" -stroke "$FONT_STROKE" -strokewidth "$FONT_STROKEWIDTH" \
                    -gravity North -font "$FONT_NAME" \
                    -pointsize "$FONT_SIZE" -annotate +0+"$title_offset" "$title" \
                    "$OUTPUT_FOLDER/$method/$filename" || exit 1
                    # -gravity North          : 垂直靠上並水平置中
                    # -pointsize "$FONT_SIZE" : 文字大小
                    # -annotate +0+10         : 向下偏移 10 像素
                # 填入副標題
                magick.exe "$OUTPUT_FOLDER/$method/$filename" \
                    -fill "$SUB_FONT_FILL" -stroke "$SUB_FONT_STROKE" -strokewidth "$SUB_FONT_STROKEWIDTH" \
                    -gravity North -font "$SUB_FONT_NAME" \
                    -pointsize "$SUB_FONT_SIZE" -annotate +0+"$subtitle_offset" "$subtitle" \
                    "$OUTPUT_FOLDER/$method/$filename" || exit 1
            fi
        done
        # 構建圖片清單
        image_list=()  # 初始化圖片清單變數
        for method in "${METHODS[@]}"; do
            # 當圖片清單不為空時，添加圖片中間的分隔線
            if [ ${#image_list[@]} -gt 0 ]; then
                image_list+=(\( -size "${SEPARATOR_WIDTH}x1" "xc:${SEPARATOR_COLOR}" -background "${SEPARATOR_COLOR}" \))
            fi
            # 將檔名加入清單
            image_list+=("$OUTPUT_FOLDER/$method/$filename")
        done
        # 合併圖片
        magick.exe "${image_list[@]}" +append "$OUTPUT_FOLDER/$MERGE_OUTPUT/$filename" || exit 1
        # 檢查是否執行單幀測試
        if [[ "$ONE_FRAME_TEST" = true ]]; then
            echo "WARNING: Exit for one frame test."
            exit 1
        fi
        # 更新進度
        ((count++))  # 更新計數
        percent=$((count * 100 / total))  # 計算百分比
        echo -ne "\r處理進度: $percent% ($count/$total) 已完成"
    done
    echo -e "\n✅ 所有圖片處理完成！"
fi

#-------------------------
# 生成所有算法的合併影片
#-------------------------
if [[ "$GENERATE_MERGE_VIDEO" = true ]]; then
    # 檢查資料夾是否存在且不為空
    if [[ ! -d "$OUTPUT_FOLDER/$MERGE_OUTPUT" ]] || [[ -z "$(ls -A "$OUTPUT_FOLDER/$MERGE_OUTPUT" 2>/dev/null)" ]]; then
        echo "ERROR! Folder $OUTPUT_FOLDER/$MERGE_OUTPUT does not exist or is empty." >&2
        exit 1
    fi
    # 生成影片
    ffmpeg.exe -loglevel error -framerate "$VIDEO_INPUT_FPS" \
        -start_number "$IMAGE_START_ID" -i "$OUTPUT_FOLDER/$MERGE_OUTPUT/$IMAGE_PREFIX%d.png" \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -pix_fmt yuv420p -r "$VIDEO_OUTPUT_FPS" \
        "$OUTPUT_FOLDER/$MERGE_OUTPUT.mp4" -y || exit 1
    echo "Video created: $MERGE_OUTPUT.mp4"
fi

echo -e "✅ 所有任務處理完成！"
