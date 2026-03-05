# terramaster F2-425-Plus
Bash script to send through curl to mqtt states of a fews sensors


# 🛠️ TerraMaster NAS to MQTT Bridge (v2.1)

Script Bash ottimizzato per il monitoraggio hardware dei NAS TerraMaster. Invia dati dettagliati a **Home Assistant** via MQTT utilizzando il protocollo di **Auto-Discovery** per una configurazione istantanea.

---

## 🇮🇹 Caratteristiche (Italiano)
* **Pieno Supporto Hardware**: Monitoraggio specifico per unità **SATA** (sda/sdb) e **NVMe** (nvme0/nvme1).
* **Auto-Discovery Resiliente**: Le configurazioni vengono inviate ciclicamente ogni 5 minuti. Se riavvii Home Assistant, i sensori riappaiono da soli.
* **Smart Data Class**: Utilizzo di `device_class` (temperature, duration, data_size, data_rate) per una corretta visualizzazione di grafici e unità di misura.
* **Analisi SMART**: Estrazione di temperatura, ore di attività (POH) e stato di salute dai dischi.
* **Leggero**: Progettato per girare in background su TOS senza pesare sulle risorse.

---

## 🇬🇧 Features (English)
* **Full Hardware Support**: Specific monitoring for **SATA** drives (sda/sdb) and **NVMe** modules (nvme0/nvme1).
* **Resilient Auto-Discovery**: Discovery payloads are sent every 5 minutes. Sensors automatically restore after a Home Assistant restart.
* **Smart Data Class**: Proper use of `device_class` (temperature, duration, data_size, data_rate) for perfect HA dashboard integration.
* **SMART Analysis**: Real-time extraction of temperature, power-on hours (POH), and health status.
* **Resource Efficient**: Minimal footprint, ideal for background execution on TOS.

---

## 📊 Sensori Monitorati / Monitored Sensors
---
<details>
<summary><b>🔍 Clicca qui per vedere la lista completa dei 26 sensori</b></summary>
  
```bash
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

```

</details>
---

## 🚀 Installazione / Installation

1. **Configura**: Inserisci l'IP del tuo Broker MQTT nello script.
2. **Permessi**: `chmod +x monitor.sh`
3. **Avvio**: `./monitor.sh &`

> [!TIP]
> Per rendere l'avvio persistente, aggiungi lo script ai **Task Programmati** (Pannello di Controllo > Utilità > Task Schedule) del tuo TerraMaster all'avvio del sistema.

---

## 🛠️ Configurazione Tecnica (SENSORS Array)
Lo script utilizza una struttura a matrice per gestire i metadati MQTT:
`NAME | UNIT | ICON | DEVICE_CLASS`

Esempio:
`SENSORS["cpu_temp"]="Temp CPU|°C|mdi:thermometer-high|temperature"`

