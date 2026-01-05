#!/bin/bash

# Yeelight Controller Setup Script
# Bu script Xcode projesini oluşturur

echo "Yeelight Controller - Setup"
echo "=========================="
echo ""

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen bulunamadi. Yukleniyor..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew bulunamadi. Lutfen once Homebrew yukleyin:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    brew install xcodegen
fi

echo "Xcode projesi olusturuluyor..."

# Navigate to project directory
cd "$(dirname "$0")"

# Generate Xcode project
xcodegen generate

if [ $? -eq 0 ]; then
    echo ""
    echo "Basarili! Xcode projesi olusturuldu."
    echo ""
    echo "Projeyi acmak icin:"
    echo "  open YeelightController.xcodeproj"
    echo ""
    echo "Veya Xcode'da File > Open ile YeelightController.xcodeproj dosyasini secin."
else
    echo ""
    echo "Hata: Xcode projesi olusturulamadi."
    echo ""
    echo "Manuel olarak Xcode'da yeni bir proje olusturun:"
    echo "1. Xcode > File > New > Project"
    echo "2. macOS > App secin"
    echo "3. Product Name: YeelightController"
    echo "4. Interface: SwiftUI, Language: Swift"
    echo "5. Olusturulan dosyalari silin ve YeelightController klasorundeki dosyalari ekleyin"
fi
