#!/bin/bash

# Основний шлях до папки Skyrim Special Edition
primary_path="/home/deck/.local/share/Steam/steamapps/common/Skyrim Special Edition"

# Шлях до знімних носіїв
removable_base_path="/run/media/deck"

# Резервний шлях до папки Skyrim Special Edition на знімному носії
secondary_path="steamapps/common/Skyrim Special Edition"

# Функція для перевірки папки та переходу до неї
check_and_change_directory() {
    if [ -d "$1" ]; then
        echo "Папка знайдена: $1"
        cd "$1" || { echo "Помилка: не вдалося перейти до папки $1"; exit 1; }
        return 0
    fi
    return 1
}

# Перевіряємо основний шлях
if ! check_and_change_directory "$primary_path"; then
    # Якщо основний шлях не знайдений, перевіряємо на знімному носії
    found=false
    for device_path in "$removable_base_path"/*; do
        if [ -d "$device_path/$secondary_path" ]; then
            echo "Знайдена папка на знімному носії: $device_path/$secondary_path"
            cd "$device_path/$secondary_path" || { echo "Помилка: не вдалося перейти до папки $device_path/$secondary_path"; exit 1; }
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        echo "Помилка: не знайдено папку Skyrim Special Edition в основному шляху або на знімному носії."
        exit 1
    fi
fi

# Перевірка, чи встановлено wget
if ! command -v wget &> /dev/null
then
    echo "wget не встановлено. Встановіть його за допомогою менеджера пакетів вашої системи."
    exit 1
fi

# Перевірка, чи встановлено unzip
if ! command -v unzip &> /dev/null
then
    echo "unzip не встановлено. Встановіть його за допомогою менеджера пакетів вашої системи."
    exit 1
fi

# Вказаний Google Drive File ID
file_id="18R5_37BjV7HjBMitolTvDs4bGkUwccYR"

# Формування посилання для завантаження
file_url="https://drive.google.com/uc?export=download&id=$file_id"

# Ім'я для завантаженого файлу
output_file="downloaded_archive.zip"

# Завантаження файлу
echo "Завантаження файлу з Google Drive..."
wget --no-check-certificate "$file_url" -O "$output_file"

# Перевірка, чи файл успішно завантажений
if [ $? -eq 0 ]; then
    echo "Файл успішно завантажено: $output_file"

    # Отримання списку файлів в архіві
    echo "Отримання списку файлів із архіву..."
    file_list=$(unzip -Z1 "$output_file")

    # Створення папки !Backup, якщо її немає
    if [ ! -d "!Backup" ]; then
        echo "Створення папки !Backup для резервного копіювання..."
        mkdir "!Backup"
    fi

    # Перевірка існування файлів у поточній папці та копіювання збігів до !Backup
    echo "Копіювання файлів, що збігаються з архівом, до папки !Backup..."
    for file in $file_list; do
        if [ -e "$file" ]; then
            echo "Файл $file вже існує. Копіювання до папки !Backup..."
            cp -p "$file" "!Backup/"
        fi
    done

    # Розпаковування архіву із перезаписом файлів
    echo "Розпаковування файлів із заміною існуючих..."
    unzip -o "$output_file" -d .

    if [ $? -eq 0 ]; then
        echo "Архів успішно розпаковано із заміною існуючих файлів!"
    else
        echo "Помилка під час розпакування."
        exit 1
    fi

    # Видалення архіву
    echo "Видалення архіву..."
    rm -f "$output_file"
    echo "Архів видалено."
else
    echo "Помилка завантаження файлу."
    exit 1
fi
