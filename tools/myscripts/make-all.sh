#!/bin/bash

# 定義指令清單
COMMANDS=(
    "./Animations/Ours-4-spatial-samples-trial/copy_files.sh"
    # "./Animations/make-video.sh"
    "./Frame_186/make-rmse.sh"
)

# 儲存初始工作目錄
INITIAL_DIR=$(pwd)

# 迭代執行指令
for cmd in "${COMMANDS[@]}"; do
    # 取得指令所在的目錄
    CMD_DIR=$(dirname "$cmd")
    CMD_NAME=$(basename "$cmd")

    echo "切換到指令所在目錄: $CMD_DIR"
    cd "$CMD_DIR" || {
        echo "切換目錄失敗: $CMD_DIR"
        exit 1
    }

    echo "正在執行: $CMD_NAME"
    ./"$CMD_NAME"
    if [ $? -ne 0 ]; then
        echo "指令失敗: $cmd"
        # 切換回初始目錄
        cd "$INITIAL_DIR"
        exit 1
    fi

    # 切換回初始目錄
    echo "切換回初始目錄: $INITIAL_DIR"
    cd "$INITIAL_DIR" || {
        echo "切換回初始目錄失敗: $INITIAL_DIR"
        exit 1
    }
done

echo "所有指令執行成功！"
