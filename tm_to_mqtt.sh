#!/bin/bash
##V 0.1
# 1. PATH DI SISTEMA
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 2. CONFIGURAZIONE
MQTT_BROKER="192.168.1.200"
DEVICE_ID="terramaster_nas"
DEVICE_NAME="TerraMaster NAS"

# 3. DISCOVERY SENSORS
declare -A SENSORS
# Formato: "Nome|Unità|Icona|Device_Class"
SENSORS["fan"]="Ventola|RPM|mdi:fan"
SENSORS["cpu"]="Carico CPU|%|mdi:cpu-64-bit"
SENSORS["ram"]="Utilizzo RAM|%|mdi:memory"
SENSORS["storage_v1"]="Volume 1|%|mdi:harddisk"
SENSORS["storage_v2"]="Volume 2|%|mdi:harddisk"
SENSORS["cpu_temp"]="Temp CPU|°C|mdi:thermometer-high|temperature"
SENSORS["sys_temp"]="Temp Sistema|°C|mdi:thermometer|temperature"
SENSORS["uptime"]="Uptime| |mdi:clock-outline"
SENSORS["temp_sda"]="Temp Disco A|°C|mdi:thermometer|temperature"
SENSORS["hours_sda"]="Ore Disco A|h|mdi:timer-sand|duration"
SENSORS["net_down"]="Download|MB/s|mdi:download-network|data_rate"
SENSORS["net_up"]="Upload|MB/s|mdi:upload-network|data_rate"
SENSORS["status_sda"]="Salute Disco A| |mdi:check-circle"
SENSORS["temp_sdb"]="Temp Disco B|°C|mdi:thermometer|temperature"
SENSORS["status_sdb"]="Salute Disco B| |mdi:check-circle"
SENSORS["hours_sdb"]="Ore Disco B|h|mdi:timer-sand|duration"
SENSORS["temp_nvme0"]="Temp NVMe 1|°C|mdi:thermometer|temperature"
SENSORS["status_nvme0"]="Salute NVMe 1| |mdi:check-circle"
SENSORS["hours_nvme0"]="Ore NVMe 1|h|mdi:timer-sand|duration"
SENSORS["temp_nvme1"]="Temp NVMe 2|°C|mdi:thermometer|temperature"
SENSORS["status_nvme1"]="Salute NVMe 2| |mdi:check-circle"
SENSORS["hours_nvme1"]="Ore NVMe 2|h|mdi:timer-sand|duration"
SENSORS["cap_sda"]="Capacità Disco A|GB|mdi:database|data_size"
SENSORS["cap_sdb"]="Capacità Disco B|GB|mdi:database|data_size"
SENSORS["cap_nv0"]="Capacità NVMe 1|GB|mdi:database-arrow-right|data_size"
SENSORS["cap_nv1"]="Capacità NVMe 2|GB|mdi:database-arrow-right|data_size"
# INVIO CONFIGURAZIONI (Discovery) con RETAIN abilitato
for ID in "${!SENSORS[@]}"; do
  # Leggiamo 4 variabili ora
  IFS='|' read -r NAME UNIT ICON CLASS <<< "${SENSORS[$ID]}"
  
  # Creiamo la parte del JSON per la device_class solo se la variabile CLASS non è vuota
  D_CLASS=""
  if [ -n "$CLASS" ]; then
    D_CLASS="\"device_class\": \"$CLASS\", "
  fi

  PAYLOAD="{$D_CLASS \"name\": \"$NAME\", \"state_topic\": \"$DEVICE_ID/$ID\", \"unit_of_measurement\": \"$UNIT\", \"icon\": \"$ICON\", \"unique_id\": \"${DEVICE_ID}_$ID\", \"device\": {\"identifiers\": [\"$DEVICE_ID\"], \"name\": \"$DEVICE_NAME\", \"model\": \"F2-425 Plus\", \"manufacturer\": \"TerraMaster\"}}"
  
  curl -s --max-time 5 "mqtt://$MQTT_BROKER/homeassistant/sensor/$DEVICE_ID/$ID/config" -d "$PAYLOAD"
done

COUNT=30

# 4. LOOP DATI
while true; do
  # Dati veloci Io uso bond0 come interfaccia voi dovete mettere la vostra
  RX1=$(cat /sys/class/net/bond0/statistics/rx_bytes)
  TX1=$(cat /sys/class/net/bond0/statistics/tx_bytes)
  sleep 1
  RX2=$(cat /sys/class/net/bond0/statistics/rx_bytes)
  TX2=$(cat /sys/class/net/bond0/statistics/tx_bytes)

  FAN=$(ec_stat -rss | grep system_fanspeed | awk '{print $3}')
  CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}')
  RAM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
  DISK1=$(df -h /Volume1 | tail -1 | awk '{print $5}' | sed 's/%//')
  DISK2=$(df -h /Volume2 | tail -1 | awk '{print $5}' | sed 's/%//')
  TEMP_CPU=$(cat /sys/class/thermal/thermal_zone1/temp | awk '{printf "%.1f", $1/1000}')
  TEMP_SYS=$(cat /sys/class/thermal/thermal_zone0/temp | awk '{printf "%.1f", $1/1000}')
  
  UP_SEC=$(cat /proc/uptime | awk '{print int($1)}')
  UP_DAYS=$((UP_SEC / 86400)); UP_HOURS=$(( (UP_SEC % 86400) / 3600 ))
  UPTIME="${UP_DAYS}d ${UP_HOURS}h"  

  NET_DOWN=$(echo "scale=2; ($RX2 - $RX1) / 1048576" | bc)
  NET_UP=$(echo "scale=2; ($TX2 - $TX1) / 1048576" | bc)

  # Invio MQTT Rapido
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cpu_temp" -d "$TEMP_CPU"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/sys_temp" -d "$TEMP_SYS"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/fan" -d "$FAN"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cpu" -d "$CPU"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/ram" -d "$RAM"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/storage_v1" -d "$DISK1"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/storage_v2" -d "$DISK2"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/uptime" -d "$UPTIME"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/net_down" -d "$NET_DOWN"
  curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/net_up" -d "$NET_UP"

  # Dati lenti (Ogni 5 min)
  if [ $COUNT -ge 30 ]; then
  # --- Re-invio Autodiscovery dopo riavvio HASS ---

  echo "Invio configurazioni Discovery a Home Assistant (Incluso Class)..."
    for ID in "${!SENSORS[@]}"; do
      # Leggiamo i 4 campi dall'array
      IFS='|' read -r NAME UNIT ICON CLASS <<< "${SENSORS[$ID]}"
      
      # Prepariamo il pezzo di JSON per la classe solo se definita
      JSON_CLASS=""
      if [ -n "$CLASS" ]; then
        JSON_CLASS="\"device_class\": \"$CLASS\", "
      fi

      # Costruiamo il payload completo
      PAYLOAD="{$JSON_CLASS \"name\": \"$NAME\", \"state_topic\": \"$DEVICE_ID/$ID\", \"unit_of_measurement\": \"$UNIT\", \"icon\": \"$ICON\", \"unique_id\": \"${DEVICE_ID}_$ID\", \"device\": {\"identifiers\": [\"$DEVICE_ID\"], \"name\": \"$DEVICE_NAME\", \"model\": \"F2-425 Plus\", \"manufacturer\": \"TerraMaster\"}}"
      
      # Invio al Broker
      curl -s --max-time 5 "mqtt://$MQTT_BROKER/homeassistant/sensor/$DEVICE_ID/$ID/config" -d "$PAYLOAD"
    done

  # --- HDD SATA (sda/sdb) ---
    T_SDA=$(smartctl -A /dev/sda | awk '$1=="194" {print $10}')
    S_SDA=$(smartctl -H /dev/sda | grep "self-assessment" | awk '{print $6}')
    H_SDA=$(smartctl -A /dev/sda | awk '$1=="9" {print $10}')

    T_SDB=$(smartctl -A /dev/sdb | awk '$1=="194" {print $10}')
    S_SDB=$(smartctl -H /dev/sdb | grep "self-assessment" | awk '{print $6}')
    H_SDB=$(smartctl -A /dev/sdb | awk '$1=="9" {print $10}')

    # --- NVMe (nvme0/nvme1) ---
    T_NV0=$(smartctl -a /dev/nvme0 | grep "Temperature:" | awk '{print $2}')
    S_NV0_RAW=$(smartctl -a /dev/nvme0 | grep "Critical Warning:" | awk '{print $3}')
    [ "$S_NV0_RAW" == "0x00" ] && S_NV0="PASSED" || S_NV0="WARNING"
    H_NV0=$(smartctl -a /dev/nvme0 | grep "Power On Hours:" | awk '{print $4}' | tr -d ',')

    T_NV1=$(smartctl -a /dev/nvme1 | grep "Temperature:" | awk '{print $2}')
    S_NV1_RAW=$(smartctl -a /dev/nvme1 | grep "Critical Warning:" | awk '{print $3}')
    [ "$S_NV1_RAW" == "0x00" ] && S_NV1="PASSED" || S_NV1="WARNING"
    H_NV1=$(smartctl -a /dev/nvme1 | grep "Power On Hours:" | awk '{print $4}' | tr -d ',')

    # --- HDD SATA (sda/sdb) ---
    C_SDA=$(smartctl -i /dev/sda | grep "User Capacity:" | grep -o '[0-9,]\+' | tr -d ',' | awk 'length($0)>10 {printf "%.0f", $1/1000000000}')
    C_SDB=$(smartctl -i /dev/sdb | grep "User Capacity:" | grep -o '[0-9,]\+' | tr -d ',' | awk 'length($0)>10 {printf "%.0f", $1/1000000000}')

    # --- NVMe (nvme0/nvme1) ---
    C_NV0=$(smartctl -i /dev/nvme0 | grep "Capacity" | grep -oE '[0-9]{1,3}(,[0-9]{3}){3,}' | tr -d ',' | head -n1 | awk '{printf "%.0f", $1/1000000000}')
    C_NV1=$(smartctl -i /dev/nvme1 | grep "Capacity" | grep -oE '[0-9]{1,3}(,[0-9]{3}){3,}' | tr -d ',' | head -n1 | awk '{printf "%.0f", $1/1000000000}')


    # Invio MQTT Capacità
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cap_sda" -d "$C_SDA"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cap_sdb" -d "$C_SDB"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cap_nv0" -d "$C_NV0"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/cap_nv1" -d "$C_NV1"
    
    # ... (mantieni gli altri curl esistenti per temp, status, hours)

    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/temp_sda" -d "$T_SDA"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/status_sda" -d "$S_SDA"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/hours_sda" -d "$H_SDA"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/temp_sdb" -d "$T_SDB"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/status_sdb" -d "$S_SDB"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/hours_sdb" -d "$H_SDB"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/temp_nvme0" -d "$T_NV0"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/status_nvme0" -d "$S_NV0"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/hours_nvme0" -d "$H_NV0"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/temp_nvme1" -d "$T_NV1"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/status_nvme1" -d "$S_NV1"
    curl -s --max-time 2 "mqtt://$MQTT_BROKER/$DEVICE_ID/hours_nvme1" -d "$H_NV1"
    
    COUNT=0
    echo "Aggiornamento SMART eseguito."
  fi

  ((COUNT++))
  sleep 9
done
