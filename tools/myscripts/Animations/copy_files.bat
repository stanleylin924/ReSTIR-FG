@echo off
REM 設定命令提示字元為 UTF-8 編碼
chcp 65001 > nul

REM 取得當前路徑
set CURRENT_DIR=%cd%

REM 來源資料夾
set SOURCE_DIR=D:\Temp\FrameCapture

REM 檢查來源資料夾是否存在
if not exist "%SOURCE_DIR%" (
    echo 錯誤：來源資料夾 "%SOURCE_DIR%" 不存在！
    exit /b 1
)

REM 刪除當前目錄下的所有 *.png 檔案
echo 正在刪除當前目錄下的所有 *.png 檔案...
del /q "%CURRENT_DIR%\*.png"
REM powershell -Command "$TargetDir = Get-Location; $FilesToDelete = Get-ChildItem -Path $TargetDir -Filter '*.png'; $Shell = New-Object -ComObject Shell.Application; foreach ($File in $FilesToDelete) { $Shell.Namespace(0).ParseName($File.FullName).InvokeVerb('delete') }; Write-Host '所有 *.png 檔案已移動到資源回收桶！'"

REM 複製來源資料夾下的所有 *.png 檔案
echo 正在複製所有 *.png 檔案...
xcopy "%SOURCE_DIR%\*.png" "%CURRENT_DIR%\" /E /H /Y

REM 確認是否成功
if %errorlevel% equ 0 (
    echo 檔案複製成功！
) else (
    echo 複製過程中發生錯誤！
)

pause
