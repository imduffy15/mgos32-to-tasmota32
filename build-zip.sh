#!/bin/bash

#Philipp "3D" ten Brink
#2023-01-19

#GNU General Public License v3.0 see LICENSE

mkdir output

tasmota_version=$(curl --silent "https://api.github.com/repos/arendst/Tasmota/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

curl -o build-files/tasmota32.bin http://ota.tasmota.com/tasmota32/release-12.5.0/tasmota32.bin
curl -o build-files/tasmota32solo1.bin http://ota.tasmota.com/tasmota32/release-12.5.0/tasmota32solo1.bin
curl -o build-files/tasmota32-lvgl.bin http://ota.tasmota.com/tasmota32/release-12.5.0/tasmota32-lvgl.bin

generatezip () {

shelly_device=$1
app_file=$2
fs_file=$3

#General:

boot_file="bootloader-tasmota.bin"
otadata_file="otadata-tasmota.bin"
partition_file="partition-table-tasmota.bin"

#Generated:

build_id=$(date '+%Y%m%d-%H%M%S')
build_date=$(date '+%Y-%m-%dT%H:%M:%SZ')
app_file_size=$(wc -c build-files/$app_file | awk '{print $1}')
app_file_cs1=$(shasum -a1 build-files/$app_file | awk '{print $1}')
app_file_cs256=$(shasum -a256 build-files/$app_file | awk '{print $1}')
boot_file_size=$(wc -c build-files/$boot_file | awk '{print $1}')
boot_file_cs1=$(shasum -a1 build-files/$boot_file | awk '{print $1}')
boot_file_cs256=$(shasum -a256 build-files/$boot_file | awk '{print $1}')
fs_file_size=$(wc -c build-files/$fs_file | awk '{print $1}')
fs_file_cs1=$(shasum -a1 build-files/$fs_file | awk '{print $1}')
fs_file_cs256=$(shasum -a256 build-files/$fs_file | awk '{print $1}')
otadata_file_size=$(wc -c build-files/$otadata_file | awk '{print $1}')
otadata_file_cs1=$(shasum -a1 build-files/$otadata_file | awk '{print $1}')
otadata_file_cs256=$(shasum -a256 build-files/$otadata_file | awk '{print $1}')
partition_file_size=$(wc -c build-files/$partition_file | awk '{print $1}')
partition_file_cs1=$(shasum -a1 build-files/$partition_file | awk '{print $1}')
partition_file_cs256=$(shasum -a256 build-files/$partition_file | awk '{print $1}')

JSON_STRING=$( jq -n \
                    --arg name "$shelly_device" \
                    --arg version "$tasmota_version" \
                    --arg build_id "$build_id/tasmota-$tasmota_version" \
                    --arg build_timestamp "$build_date" \
                    --arg app_file "$app_file" \
                    --argjson app_file_size $app_file_size \
                    --arg app_cs_sha1 "$app_file_cs1" \
                    --arg app_cs_sha256 "$app_file_cs256" \
                    --arg boot_file "$boot_file" \
                    --argjson boot_file_size $boot_file_size \
                    --arg boot_cs_sha1 "$boot_file_cs1" \
                    --arg boot_cs_sha256 "$boot_file_cs256" \
                    --arg fs_file "$fs_file" \
                    --argjson fs_file_size $fs_file_size \
                    --arg fs_cs_sha1 "$fs_file_cs1" \
                    --arg fs_cs_sha256 "$fs_file_cs256" \
                    --arg otadata_file "$otadata_file" \
                    --argjson otadata_file_size $otadata_file_size \
                    --arg otadata_cs_sha1 "$otadata_file_cs1" \
                    --arg otadata_cs_sha256 "$otadata_file_cs256" \
                    --arg partition_file "$partition_file" \
                    --argjson partition_file_size $partition_file_size \
                    --arg partition_cs_sha1 "$partition_file_cs1" \
                    --arg partition_cs_sha256 "$partition_file_cs256" \
'{ "name" : $name, "platform" : "esp32", "version" : $version, "build_id" : $build_id, "build_timestamp" : $build_timestamp, "parts": { "app": { "type": "app", "src": $app_file, "size": $app_file_size, "cs_sha1" : $app_cs_sha1, "cs_sha256" : $app_cs_sha256, "encrypt": true, "ptn": "app_0"}, "boot": { "type": "boot", "src": $boot_file, "addr": 4096, "size": $boot_file_size, "cs_sha1" : $boot_cs_sha1, "cs_sha256": $boot_cs_sha256, "encrypt": true, "update": true }, "fs": { "type": "fs", "src": $fs_file, "size": $fs_file_size, "cs_sha1": $fs_cs_sha1, "cs_sha256": $fs_cs_sha256, "fs_size": $fs_file_size, "encrypt": true, "ptn": "fs_1" }, "nvs": { "type": "nvs", "size": 16384, "fill": 255, "ptn": "nvs" }, "otadata": { "type": "otadata", "src": $otadata_file, "size": $otadata_file_size, "cs_sha1": $otadata_cs_sha1, "cs_sha256": $otadata_cs_sha256, "encrypt": true, "ptn": "otadata"}, "pt": { "type": "pt", "src": $partition_file, "addr": 32768, "size": $partition_file_size, "cs_sha1": $partition_cs_sha1, "cs_sha256": $partition_cs_sha256, "encrypt": true }}}')

printf "$JSON_STRING" > build-files/manifest.json

cd build-files
zip -0 mgos32-to-tasmota32-$shelly_device.zip manifest.json $app_file $boot_file $fs_file $otadata_file $partition_file
mv mgos32-to-tasmota32-$shelly_device.zip ../output/
cd ..

printf "\nDone mgos32-to-tasmota32-$shelly_device.zip\n\n"

} 

ShellyPlus=( PlusHT PlusPlugUK PlusPlugS PlugIT PlugUS PlugUK PlusI4 PlusWallDimmer Plus1PM Plus1 Plus2PM )
for i in "${ShellyPlus[@]}"
do
    generatezip $i "tasmota32solo1.bin" "fs-4MB-tasmota.img"
done

ShellyPro8MB=( Pro1 Pro1PM Pro2 Pro2PM Pro3 )
for i in "${ShellyPro8MB[@]}"
do
    generatezip $i "tasmota32.bin" "fs-8MB-tasmota.img"
done

ShellyPro8MBlvgl=( Pro4PM )
for i in "${ShellyPro8MBlvgl[@]}"
do
    generatezip $i "tasmota32-lvgl.bin" "fs-8MB-tasmota.img"
done

ShellyPro16MB=( Pro3EM )
for i in "${ShellyPro16MB[@]}"
do
    generatezip $i "tasmota32.bin" "fs-16MB-tasmota.img"
done
