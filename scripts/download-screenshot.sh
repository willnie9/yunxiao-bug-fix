#!/bin/bash
# 下载云效工作项截图
# 用法: ./download-screenshot.sh <下载链接> <输出文件名>

set -e

if [ "$#" -ne 2 ]; then
    echo "用法: $0 <下载链接> <输出文件名>"
    echo "示例: $0 'https://yunxiao.aliyun.com/...' screenshot.png"
    exit 1
fi

DOWNLOAD_URL="$1"
OUTPUT_FILE="$2"

echo "📥 正在从云效下载截图..."
echo "链接: $DOWNLOAD_URL"
echo "输出: $OUTPUT_FILE"

# 使用 curl 下载
curl -L -o "$OUTPUT_FILE" "$DOWNLOAD_URL"

if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    echo "✅ 下载完成！文件大小: $FILE_SIZE 字节"
    echo "📁 保存到: $OUTPUT_FILE"
else
    echo "❌ 下载失败！"
    exit 1
fi
