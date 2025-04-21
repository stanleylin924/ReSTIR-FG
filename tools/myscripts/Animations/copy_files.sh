#!/bin/bash

# 設定命令提示字元為 UTF-8 編碼
export LANG=en_US.UTF-8

# 取得腳本所在路徑
CURRENT_DIR=$(dirname "$(realpath "$0")")

# 來源資料夾
SOURCE_DIR="/mnt/d/Temp/FrameCapture"

# 檢查來源資料夾是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "錯誤：來源資料夾 \"$SOURCE_DIR\" 不存在！"
    exit 1
fi

# 刪除當前目錄下的所有 *.png 檔案
echo "正在刪除目標資料夾 \"$CURRENT_DIR\" 下的所有 *.png 檔案..."
rm -f "${CURRENT_DIR}"/*.png

# 複製來源資料夾下的所有 *.png 檔案
echo "正在複製所有 *.png 檔案到目標資料夾..."
cp -r "${SOURCE_DIR}"/*.png "${CURRENT_DIR}/"

# 確認是否成功
if [ $? -eq 0 ]; then
    echo "檔案複製成功！"
else
    echo "複製過程中發生錯誤！"
    exit 1
fi
