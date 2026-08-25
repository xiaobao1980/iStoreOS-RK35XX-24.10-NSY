#!/bin/bash
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# --------------------------------------------------
# 步骤0: 清洗 .config（hardening，避免 missing separator）
# OpenWrt 在 prepare-tmpinfo 阶段把 .config 当作 Makefile include 解析；
# 若存在缺失前导 # 的 "xxx is not set" 行，make 会把 CONFIG_X 当成无分隔符
# 的 target 而报 “*** missing separator”。此处统一兜底修复，对干净配置无副作用。
# --------------------------------------------------
if [ -f .config ]; then
	echo "==> 清洗 .config：修复缺失前导 # 的 is not set 行"
	sed -i -E 's/^(CONFIG_[^ ]+ is not set)$/# \1/' .config
	# 去 CR / BOM / 行首尾空白 / 空行 / 行首 TAB
	sed -i -e 's/\r$//' -e '1s/^\xEF\xBB\xBF//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' .config
fi

# 修改uhttpd配置文件，启用nginx
# sed -i "/.*uhttpd.*/d" .config
# sed -i '/.*\/etc\/init.d.*/d' package/network/services/uhttpd/Makefile
# sed -i '/.*.\/files\/uhttpd.init.*/d' package/network/services/uhttpd/Makefile
sed -i "s/:80/:81/g" package/network/services/uhttpd/files/uhttpd.config
sed -i "s/:443/:4443/g" package/network/services/uhttpd/files/uhttpd.config
cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/
# ls package/base-files/files/etc/


# 追加自定义内核配置项
echo "CONFIG_PSI=y
CONFIG_KPROBES=y" >> target/linux/rockchip/armv8/config-6.6


# 集成CPU性能跑分脚本
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64 package/base-files/files/bin/coremark-arm64
cp -f $GITHUB_WORKSPACE/configfiles/coremark/coremark-arm64.sh package/base-files/files/bin/coremark.sh
chmod 755 package/base-files/files/bin/coremark-arm64
chmod 755 package/base-files/files/bin/coremark.sh


# iStoreOS-settings
git clone --depth=1 -b main https://github.com/xiaobao1980/istoreos-settings package/default-settings


# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus



# 增加nsy_g68-plus
echo -e "\\ndefine Device/nsy_g68-plus
\$(call Device/Legacy/rk3568,\$(1))
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G68
  DEVICE_DTS := rk3568/rk3568-nsy-g68-plus
  DEVICE_PACKAGES += kmod-nvme kmod-ata-ahci-dwc kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8169 kmod-mt7916-firmware
endef
TARGET_DEVICES += nsy_g68-plus" >> target/linux/rockchip/image/legacy.mk


# 增加nsy_g16-plus
echo -e "\\ndefine Device/nsy_g16-plus
\$(call Device/Legacy/rk3568,\$(1))
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G16
  DEVICE_DTS := rk3568/rk3568-nsy-g16-plus
  DEVICE_PACKAGES += kmod-nvme kmod-ata-ahci-dwc kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8169 kmod-mt7615-firmware
endef
TARGET_DEVICES += nsy_g16-plus" >> target/linux/rockchip/image/legacy.mk


# 增加bdy_g18-pro
echo -e "\\ndefine Device/bdy_g18-pro
\$(call Device/Legacy/rk3568,\$(1))
  DEVICE_VENDOR := BDY
  DEVICE_MODEL := G18
  DEVICE_DTS := rk3568/rk3568-bdy-g18-pro
  DEVICE_PACKAGES += kmod-nvme kmod-ata-ahci-dwc kmod-hwmon-pwmfan kmod-thermal kmod-switch-rtl8306 kmod-switch-rtl8366-smi kmod-switch-rtl8366rb kmod-switch-rtl8366s kmod-switch-rtl8367b swconfig kmod-swconfig kmod-r8169 kmod-mt7615-firmware
endef
TARGET_DEVICES += bdy_g18-pro" >> target/linux/rockchip/image/legacy.mk


# 复制 02_network 网络配置文件到 target/linux/rockchip/armv8/base-files/etc/board.d/ 目录下
cp -f $GITHUB_WORKSPACE/configfiles/02_network target/linux/rockchip/armv8/base-files/etc/board.d/02_network


# 加入初始化交换机脚本
cp -f $GITHUB_WORKSPACE/configfiles/swconfig_install package/base-files/files/etc/init.d/swconfig_install
chmod 755 package/base-files/files/etc/init.d/swconfig_install


# 集成 nsy_g68-plus WiFi驱动
mkdir -p package/base-files/files/lib/firmware/mediatek
cp -f $GITHUB_WORKSPACE/configfiles/WirelessDriver/mt7916_eeprom.bin package/base-files/files/lib/firmware/mediatek/mt7916_eeprom.bin
cp -f $GITHUB_WORKSPACE/configfiles/WirelessDriver/mt7916_eeprom_backup.bin package/base-files/files/lib/firmware/mediatek/mt7916_eeprom_backup.bin
cp -f $GITHUB_WORKSPACE/configfiles/opwifi package/base-files/files/etc/init.d/opwifi
chmod 755 package/base-files/files/etc/init.d/opwifi


# 电工大佬的rtl8367b驱动资源包，暂时使用这样替换
wget https://github.com/xiaobao1980/files/releases/download/files/rtl8367b.tar.gz
tar -xvf rtl8367b.tar.gz


# 复制dts设备树文件到指定目录下
cp -a $GITHUB_WORKSPACE/configfiles/dts/rk3568/* target/linux/rockchip/dts/rk3568/
cp -a $GITHUB_WORKSPACE/configfiles/dts/rk3588/* target/linux/rockchip/dts/rk3588/


# ============================================================
# ROCEOS K50S / K50S MAX 适配
# K50S MAX 与 K50S 同 PCB（RK3568），直接复用 K50S 的 DTS/DTSI，
# 仅由 rk3568-roceos-k50s-max.dts 覆盖 model/compatible 生成独立 DTB。
# 三个 DTS 文件已放入 configfiles/dts/rk3568/，上面 cp 会自动进内核树。
# 设备定义追加到 legacy.mk（与 nsy/bdy 同一机制），用 Device/Legacy/rk3568。
# ============================================================
echo "==================== ROCEOS K50S / K50S MAX 适配开始 ===================="

MK_FILE="target/linux/rockchip/image/legacy.mk"
CONFIG_K50S_LINES=(
	"CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_roceos_k50s=y"
	"CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_roceos_k50s_max=y"
)

# --- legacy.mk 追加 K50S / K50S MAX 设备定义（复用 K50S DTB，防重复） ---
# 每个设备定义独立守卫：若上游内核树已内置同名设备，则不再追加，避免重复定义报错。
if [ -f "${MK_FILE}" ]; then
	if ! grep -q "define Device/roceos_k50s$" "${MK_FILE}"; then
		cat >> "${MK_FILE}" << 'MK_EOF'

define Device/roceos_k50s
  $(call Device/Legacy/rk3568,$(1))
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S
  DEVICE_DTS := rk3568/rk3568-roceos-k50s
  DEVICE_PACKAGES += kmod-r8125 kmod-thermal kmod-hwmon-pwmfan kmod-usb-storage kmod-usb-storage-uas kmod-nvme kmod-ata-ahci kmod-brcmfmac brcmfmac-firmware-43455-sdio wpad-basic-mbedtls
endef
TARGET_DEVICES += roceos_k50s
MK_EOF
		echo "==> legacy.mk 已添加 ROCEOS K50S 设备定义"
	else
		echo "==> legacy.mk 已存在 K50S，跳过"
	fi
	if ! grep -q "define Device/roceos_k50s_max$" "${MK_FILE}"; then
		cat >> "${MK_FILE}" << 'MK_EOF'

define Device/roceos_k50s_max
  $(call Device/Legacy/rk3568,$(1))
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S MAX
  DEVICE_DTS := rk3568/rk3568-roceos-k50s-max
  DEVICE_PACKAGES += kmod-r8125 kmod-thermal kmod-hwmon-pwmfan kmod-usb-storage kmod-usb-storage-uas kmod-nvme kmod-ata-ahci kmod-brcmfmac brcmfmac-firmware-43455-sdio wpad-basic-mbedtls
endef
TARGET_DEVICES += roceos_k50s_max
MK_EOF
		echo "==> legacy.mk 已添加 ROCEOS K50S MAX 设备定义"
	else
		echo "==> legacy.mk 已存在 K50S MAX，跳过"
	fi
else
	echo "警告: 未找到 ${MK_FILE}，跳过设备定义追加"
fi

# --- .config 追加设备选择 ---
for line in "${CONFIG_K50S_LINES[@]}"; do
	key=$(echo "$line" | cut -d= -f1)
	if ! grep -q "^${key}=y" .config 2>/dev/null; then
		echo "$line" >> .config
	fi
done
echo "==> .config 已更新 (ROCEOS K50S / K50S MAX)"

echo "==================== ROCEOS K50S / K50S MAX 适配完成 ===================="
