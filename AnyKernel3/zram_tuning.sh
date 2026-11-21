#!/system/bin/sh
# zram_tuning.sh - Post-boot storage, VM, and persistence tuning for Xiaomi Pad 5 (nabu)

# Wait until boot is completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Match Qualcomm SM8150 VM defaults (keep ZRAM as vendor-configured LZ4 without boot-time swapoff)
echo 60 > /proc/sys/vm/swappiness
echo 100 > /proc/sys/vm/vfs_cache_pressure

# Configure mq-deadline I/O scheduler for blk-mq UFS internal storage (avoids 4.14 BFQ lock/idle stalls)
for queue in /sys/block/sd*/queue/scheduler; do
    if [ -f "$queue" ]; then
        echo mq-deadline > "$queue" 2>/dev/null || echo none > "$queue" 2>/dev/null
    fi
done

# Ensure /data/property permissions remain secure for Android init persistence
if [ -f /data/property/persistent_properties ]; then
    chmod 600 /data/property/persistent_properties 2>/dev/null || true
    chown 0:0 /data/property/persistent_properties 2>/dev/null || true
fi
chmod 700 /data/property 2>/dev/null || true
chown 0:0 /data/property 2>/dev/null || true

# Disable auto_time_zone on Wi-Fi only tablet only if not already disabled
if [ "$(settings get global auto_time_zone 2>/dev/null)" != "0" ]; then
    settings put global auto_time_zone 0 2>/dev/null || true
fi
