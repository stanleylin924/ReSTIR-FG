#!/bin/bash

mkdir -p output output/ReSTIR-GI output/ReSTIR-PT output/ReSTIR-FG output/Ours output/Merge  # 確保資料夾存在

files=(Ours/*.png)              # 取得所有檔案
total=${#files[@]}              # 計算總數
count=0                         # 已處理的檔案數

for file in "${files[@]}"; do
    filename=$(basename "$file")  # 取得檔名 (不含路徑)
    # 裁剪
    magick.exe "ReSTIR-GI/$filename" -crop 320x800+530+0 +repage "output/ReSTIR-GI/$filename"
    magick.exe "ReSTIR-PT/$filename" -crop 320x800+530+0 +repage "output/ReSTIR-PT/$filename"
    magick.exe "ReSTIR-FG/$filename" -crop 320x800+530+0 +repage "output/ReSTIR-FG/$filename"
    magick.exe "Ours/$filename" -crop 320x800+530+0 +repage "output/Ours/$filename"
    # 合併
    magick.exe "output/ReSTIR-GI/$filename" "output/ReSTIR-PT/$filename" "output/ReSTIR-FG/$filename" "output/Ours/$filename" +append "output/Merge/$filename"
    # 添加文字
    magick.exe "output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text   20,750 'ReSTIR GI'" "output/Merge/$filename"
    magick.exe "output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text  340,750 'ReSTIR PT'" "output/Merge/$filename"
    magick.exe "output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text  655,750 'ReSTIR FG'" "output/Merge/$filename"
    magick.exe "output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text 1060,750 'Ours'"      "output/Merge/$filename"
    # 添加框線
    magick.exe "output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 319,0,319,800" "output/Merge/$filename"
    magick.exe "output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 639,0,639,800" "output/Merge/$filename"
    magick.exe "output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 959,0,959,800" "output/Merge/$filename"

    ((count++))  # 更新計數
    percent=$((count * 100 / total))  # 計算百分比
    echo -ne "\r處理進度: $percent% ($count/$total) 已完成"
done
ffmpeg.exe -framerate 6 -start_number 1 -i output/Merge/%04d.png -t 30 -c:v libx264 -pix_fmt yuv420p -r 30 output/Merge.mp4 -y 2>/dev/null
echo -e "\n✅ 所有圖片處理完成！"
