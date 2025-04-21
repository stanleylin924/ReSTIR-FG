#!/bin/bash

mkdir -p Output Output/ReSTIR-GI Output/ReSTIR-FG Output/Ours-1-spatial-sample Output/Ours-4-spatial-samples Output/Ours-4-spatial-samples-accumulate Output/Merge  # 確保資料夾存在

files=(ReSTIR-GI/*.png)         # 取得所有檔案
total=${#files[@]}              # 計算總數
count=0                         # 已處理的檔案數

for file in "${files[@]}"; do
    filename=$(basename "$file")  # 取得檔名 (不含路徑)
    # 裁剪
    magick.exe "ReSTIR-GI/$filename" -crop 420x800+480+0 +repage "Output/ReSTIR-GI/$filename"
    magick.exe "ReSTIR-FG/$filename" -crop 420x800+480+0 +repage "Output/ReSTIR-FG/$filename"
    magick.exe "Ours-4-spatial-samples/$filename" -crop 420x800+480+0 +repage "Output/Ours-4-spatial-samples/$filename"
    magick.exe "Ours-4-spatial-samples-accumulate/$filename" -crop 420x800+480+0 +repage "Output/Ours-4-spatial-samples-accumulate/$filename"
    # 合併
    magick.exe "Output/ReSTIR-GI/$filename" "Output/ReSTIR-FG/$filename" "Output/Ours-4-spatial-samples/$filename" "Output/Ours-4-spatial-samples-accumulate/$filename" +append "Output/Merge/$filename"
    # 添加文字
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text   70,750 'ReSTIR GI'" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text  485,750 'ReSTIR FG'" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text  980,740 'Ours'" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 33 -draw "text  910,780 'w/o accumulation'" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 55 -draw "text 1420,740 'Ours'" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -font "Arial-Bold" -fill white -stroke black -strokewidth 2 -pointsize 33 -draw "text 1350,780 'w/ accumulation'" "Output/Merge/$filename"
    # 添加框線
    magick.exe "Output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 419,0,419,800" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 839,0,839,800" "Output/Merge/$filename"
    magick.exe "Output/Merge/$filename" -strokewidth 3 -stroke black -draw "line 1259,0,1259,800" "Output/Merge/$filename"
    # 更新進度
    ((count++))  # 更新計數
    percent=$((count * 100 / total))  # 計算百分比
    echo -ne "\r處理進度: $percent% ($count/$total) 已完成"
done
prefix="Mogwai.ToneMapper.dst"
startid=179
ffmpeg.exe -framerate 6 -start_number $startid -i Output/Merge/"$prefix".%d.png -t 30 -c:v libx264 -pix_fmt yuv420p -r 30 Output/Merge.mp4 -y 2>/dev/null
echo -e "\n✅ 所有圖片處理完成！"
