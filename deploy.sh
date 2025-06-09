#!/bin/bash

# CyFishON - Скрипт автоматической сборки и установки
# Использование: ./deploy.sh

echo "🎣 CyFishON - Автоматическая сборка и установка"
echo "=============================================="

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# IP адрес телефона (можно изменить если нужно)
PHONE_IP="192.168.1.189"
ADB_PORT="5555"

# Функция для проверки подключения
check_connection() {
    echo -e "${YELLOW}📱 Проверяем подключение к телефону...${NC}"
    
    # Проверяем, подключен ли телефон
    if adb devices | grep -q "${PHONE_IP}:${ADB_PORT}"; then
        echo -e "${GREEN}✅ Телефон подключен по WiFi${NC}"
        return 0
    else
        echo -e "${RED}❌ Телефон не подключен${NC}"
        echo -e "${YELLOW}🔄 Пытаемся подключиться...${NC}"
        
        # Пытаемся подключиться
        adb connect ${PHONE_IP}:${ADB_PORT} > /dev/null 2>&1
        
        # Проверяем еще раз
        if adb devices | grep -q "${PHONE_IP}:${ADB_PORT}"; then
            echo -e "${GREEN}✅ Подключение восстановлено${NC}"
            return 0
        else
            echo -e "${RED}❌ Не удалось подключиться к телефону${NC}"
            echo -e "${YELLOW}💡 Убедитесь что:${NC}"
            echo "   - Телефон подключен к той же WiFi сети"
            echo "   - IP адрес телефона: ${PHONE_IP}"
            echo "   - Отладка по WiFi включена"
            echo ""
            echo -e "${YELLOW}🔧 Для первоначальной настройки:${NC}"
            echo "   1. Подключите телефон по USB"
            echo "   2. Выполните: adb tcpip 5555"
            echo "   3. Отключите USB и запустите скрипт снова"
            return 1
        fi
    fi
}

# Функция автоинкремента версии
increment_version() {
    echo -e "${YELLOW}📈 Обновляем версию приложения...${NC}"
    
    # Читаем текущую версию из pubspec.yaml
    current_version=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
    
    if [ -z "$current_version" ]; then
        echo -e "${RED}❌ Не удалось найти версию в pubspec.yaml${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📋 Текущая версия: $current_version${NC}"
    
    # Разбираем версию на части (major.minor.patch)
    IFS='.' read -r major minor patch <<< "$current_version"
    
    # Увеличиваем patch версию
    new_patch=$((patch + 1))
    new_version="$major.$minor.$new_patch"
    
    # Получаем build number (увеличиваем на 1)
    current_build=$(grep "^version:" pubspec.yaml | sed 's/.*+//')
    if [ -z "$current_build" ]; then
        current_build=1
    fi
    new_build=$((current_build + 1))
    
    # Обновляем pubspec.yaml
    sed -i.bak "s/^version:.*/version: $new_version+$new_build/" pubspec.yaml
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Версия обновлена: $new_version+$new_build${NC}"
        rm pubspec.yaml.bak 2>/dev/null
        return 0
    else
        echo -e "${RED}❌ Ошибка обновления версии${NC}"
        return 1
    fi
}

# Функция сборки APK
build_apk() {
    echo -e "${YELLOW}🔨 Собираем APK...${NC}"
    
    if flutter build apk --release; then
        echo -e "${GREEN}✅ APK успешно собран${NC}"
        return 0
    else
        echo -e "${RED}❌ Ошибка сборки APK${NC}"
        return 1
    fi
}

# Функция установки APK
install_apk() {
    echo -e "${YELLOW}📲 Устанавливаем APK на телефон...${NC}"
    
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ ! -f "$APK_PATH" ]; then
        echo -e "${RED}❌ APK файл не найден: $APK_PATH${NC}"
        return 1
    fi
    
    if adb install -r "$APK_PATH"; then
        echo -e "${GREEN}✅ APK успешно установлен${NC}"
        return 0
    else
        echo -e "${RED}❌ Ошибка установки APK${NC}"
        return 1
    fi
}

# Функция запуска приложения
launch_app() {
    echo -e "${YELLOW}🚀 Запускаем приложение...${NC}"
    
    # Пакет приложения
    PACKAGE_NAME="com.example.cyfishon"
    ACTIVITY_NAME="com.example.cyfishon.MainActivity"
    
    if adb shell am start -n "${PACKAGE_NAME}/${ACTIVITY_NAME}" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Приложение запущено${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Не удалось автоматически запустить приложение${NC}"
        echo -e "${YELLOW}💡 Запустите CyFishON вручную на телефоне${NC}"
        return 0
    fi
}

# Функция показа логов
show_logs() {
    echo -e "${YELLOW}📋 Показываем логи приложения...${NC}"
    echo -e "${YELLOW}💡 Нажмите Ctrl+C для выхода из логов${NC}"
    echo ""
    
    # Очищаем старые логи и показываем новые
    adb logcat -c
    adb logcat | grep -i "flutter\|cyfishon\|error\|exception"
}

# Основная функция
main() {
    echo ""
    
    # Проверяем подключение
    if ! check_connection; then
        exit 1
    fi
    
    echo ""
    
    # Обновляем версию
    if ! increment_version; then
        exit 1
    fi
    
    echo ""
    
    # Собираем APK
    if ! build_apk; then
        exit 1
    fi
    
    echo ""
    
    # Устанавливаем APK
    if ! install_apk; then
        exit 1
    fi
    
    echo ""
    
    # Запускаем приложение
    launch_app
    
    echo ""
    echo -e "${GREEN}🎉 Готово! Приложение установлено и запущено${NC}"
    echo ""
    
    # Спрашиваем, показать ли логи
    read -p "Показать логи приложения? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs
    fi
}

# Запускаем основную функцию
main
