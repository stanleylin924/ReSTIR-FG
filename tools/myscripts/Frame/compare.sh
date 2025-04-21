#!/bin/bash

mkdir -p Output  # 確保資料夾存在

# 裁剪
files=("Reference" "ReSTIR-GI" "ReSTIR-PT" "ReSTIR-FG" "Ours")  # 定義一個名為 files 的陣列：檔案清單
for file in "${files[@]}"; do  # 使用 ${files[@]} 來迭代陣列中的所有元素
    magick.exe "Input/$file.png" -crop 100x100+640+0 "Output/img1-$file.png"
    magick.exe "Input/$file.png" -crop 64x64+588+352 "Output/img2-$file.png"
done

# 畫框
magick.exe "Input/Reference.png" -fill none -stroke "rgb(254, 191, 0)" -strokewidth 5 -draw "rectangle 640,0 740,100" "Output/marked-Reference.png"
magick.exe "Output/marked-Reference.png" -fill none -stroke "rgb(1, 112, 191)" -strokewidth 5 -draw "rectangle 588,352 652,416" "Output/marked-Reference.png"

# 計算 RMSE
cd Output
> rmse_results.txt  # 清空檔案
for i in $(seq 1 2); do
    echo -e "\n*** img$i ***" | tee -a rmse_results.txt
    for file in "${files[@]:1}"; do  # 使用 ${files[@]:1} 從陣列中的第二個元素開始迭代
        echo -n "$file: " | tee -a rmse_results.txt
        magick.exe compare -metric RMSE "img$i-Reference.png" "img$i-$file.png" null: 2>&1 | awk -F '[()]' '{print $2}' | tee -a rmse_results.txt
    done
done

echo -e "\n✅ 所有圖片處理完成！"
