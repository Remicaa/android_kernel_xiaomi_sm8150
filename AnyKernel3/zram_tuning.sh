#!/system/bin/sh
# zram_tuning.sh - Optimizes ZRAM and VM tunables for Xiaomi Pad 5 (nabu)

# Wait until boot is completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Ensure page-cluster is 0 for RAM-backed zram
echo 0 > /proc/sys/vm/page-cluster

# Optimal swappiness & cache pressure for ZSTD zram
echo 100 > /proc/sys/vm/swappiness
echo 80 > /proc/sys/vm/vfs_cache_pressure

# Configure BFQ I/O scheduler for UFS internal storage
for queue in /sys/block/sd*/queue/scheduler; do
    if [ -f "$queue" ]; then
        echo bfq > "$queue" 2>/dev/null || echo mq-deadline > "$queue" 2>/dev/null
    fi
done

# Ensure Schedutil iowait boosting is enabled across all CPU clusters
for boost in /sys/devices/system/cpu/cpufreq/policy*/schedutil/iowait_boost_enable; do
    if [ -f "$boost" ]; then
        echo 1 > "$boost" 2>/dev/null
    fi
done

# If zram size is currently below 4.5GB, expand to 4.5GB (4718592000 bytes)
TARGET_SIZE=4718592000 # 4.5 GiB
CURRENT_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)

if [ -n "$CURRENT_SIZE" ] && [ "$CURRENT_SIZE" -lt "$TARGET_SIZE" ]; then
    swapoff /dev/block/zram0 2>/dev/null
    echo 1 > /sys/block/zram0/reset 2>/dev/null
    echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || echo lz4 > /sys/block/zram0/comp_algorithm
    echo $TARGET_SIZE > /sys/block/zram0/disksize
    mkswap /dev/block/zram0
    swapon /dev/block/zram0 -p 32767
fi
