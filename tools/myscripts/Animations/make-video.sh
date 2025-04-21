#!/bin/bash

mkdir -p Output  # 確保資料夾存在

dirs=("ReSTIR-GI" "ReSTIR-FG" "Ours-4-spatial-samples")  # 定義一個名為 dirs 的陣列：目錄清單
prefix="Mogwai.ToneMapper.dst"
startid=179

for dir in "${dirs[@]}"  # 使用 ${dirs[@]} 來迭代陣列中的所有元素
do
    if [ -d "$dir" ]; then  # 檢查目錄是否存在
        echo "輸出 $dir.mp4 ..."
        ffmpeg.exe -framerate 6 -start_number $startid -i "$dir"/"$prefix".%d.png -t 30 -c:v libx264 -pix_fmt yuv420p -r 30 Output/"$dir".mp4 -y 2>/dev/null
    else
        echo "目錄 $dir 不存在"
    fi
done
