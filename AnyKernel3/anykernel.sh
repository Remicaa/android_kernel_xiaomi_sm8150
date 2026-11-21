### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Fresh Kernel (ThinLTO) for Xiaomi Pad 5 (nabu)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=nabu
device.name2=Xiaomi Pad 5
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

write_boot;
## end boot install

# install zram tuning service into /data/adb/service.d if available
mount /data 2>/dev/null;
if [ -d /data/adb ]; then
  ui_print " ";
  ui_print "- Installing post-boot tuning script to /data/adb/service.d/...";
  mkdir -p /data/adb/service.d;
  cp -f $home/zram_tuning.sh /data/adb/service.d/zram_tuning.sh;
  chmod 755 /data/adb/service.d/zram_tuning.sh;
  chown 0:0 /data/adb/service.d/zram_tuning.sh;
  if [ -d $home/modules_ko ]; then
    ui_print "- Installing loadable Wi-Fi modules to /data/adb/modules_ko/...";
    mkdir -p /data/adb/modules_ko;
    cp -f $home/modules_ko/*.ko /data/adb/modules_ko/ 2>/dev/null || true;
    chmod 644 /data/adb/modules_ko/*.ko 2>/dev/null || true;
  fi
  if [ -d $home/aic8800/fw ]; then
    ui_print "- Installing AIC8800D80 modules and firmware to /data/adb/aic8800/...";
    mkdir -p /data/adb/aic8800/fw;
    cp -f $home/aic8800/fw/* /data/adb/aic8800/fw/ 2>/dev/null || true;
    cp -f $home/modules_ko/aic_load_fw.ko /data/adb/aic8800/ 2>/dev/null || true;
    cp -f $home/modules_ko/aic8800_fdrv.ko /data/adb/aic8800/ 2>/dev/null || true;
    chmod 644 /data/adb/aic8800/*.ko /data/adb/aic8800/fw/* 2>/dev/null || true;
  fi
fi
