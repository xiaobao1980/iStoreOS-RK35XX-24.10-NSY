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
git clone --depth=1 -b main https://github.com/xiaomeng9597/istoreos-settings package/default-settings


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
wget https://github.com/xiaomeng9597/files/releases/download/files/rtl8367b.tar.gz
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
#
# K50S 硬件 Console 口固定 115200，而 iStoreOS 默认 rk3568 引导链为
# 1500000，因此新增 U-Boot 变体 easepi-rk3568-uart2-115200 + 专用
# bootscript，使 DDR/U-Boot/内核三阶段统一 115200。
# ============================================================
echo "==================== ROCEOS K50S / K50S MAX 适配开始 ===================="

MK_FILE="target/linux/rockchip/image/legacy.mk"
UBOOT_MK="package/boot/uboot-rockchip/Makefile"
CONFIG_K50S_LINES=(
	"CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_roceos_k50s=y"
	"CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_roceos_k50s_max=y"
)

# --- 复制 K50S 专用 115200 U-Boot 文件与 bootscript ---
if [ -d "$GITHUB_WORKSPACE/configfiles/uboot-rockchip/src" ]; then
	cp -a "$GITHUB_WORKSPACE/configfiles/uboot-rockchip/src/"* package/boot/uboot-rockchip/src/
	echo "==> U-Boot 源码覆盖文件已复制"
fi
if [ -f "$GITHUB_WORKSPACE/configfiles/bootscript/rk3568-uart2-115200.bootscript" ]; then
	cp -f "$GITHUB_WORKSPACE/configfiles/bootscript/rk3568-uart2-115200.bootscript" target/linux/rockchip/image/legacy/
	echo "==> bootscript rk3568-uart2-115200 已复制"
fi

# --- K50S MAX: 内核补丁复制到 target/linux/rockchip/patches-6.6（构建时 quilt 自动应用）---
# 990-dwc-pcie-extend-link-wait.patch: lane1 训练慢，等待窗口 ~1s -> ~10s。
# 991-dts-rk3568-move-pcie3x1-after-pcie3x2.patch: lane1 的 RTL8125 要等
# pcie3x2（bifurcation 主控）probe/复位后才可训练（疑似 PERST# 共用 PA4），
# 把 base dtsi 里 pcie3x1 节点移到 pcie3x2 之后使主控先 probe。
if [ -d "$GITHUB_WORKSPACE/configfiles/patches-6.6" ]; then
	mkdir -p target/linux/rockchip/patches-6.6
	cp -a "$GITHUB_WORKSPACE/configfiles/patches-6.6/"* target/linux/rockchip/patches-6.6/
	echo "==> K50S 内核补丁已复制到 target/linux/rockchip/patches-6.6/"
fi

# --- 部署 rc.local（本 workflow 只跑 part1+part2，diy-part3 的 rc.local 拷贝不会执行）---
# rc.local 内含 K50S lane1 RTL8125 的运行期 rescan 兜底。
cp -f $GITHUB_WORKSPACE/configfiles/rc.local package/base-files/files/etc/rc.local
chmod 755 package/base-files/files/etc/rc.local
echo "==> rc.local 已部署"

# --- 在 uboot-rockchip/Makefile 注册新的 115200 变体 ---
if [ -f "$UBOOT_MK" ] && ! grep -q "U-Boot/easepi-rk3568-uart2-115200" "$UBOOT_MK"; then
	awk '
	/^define U-Boot\/easepi-rk3568-rk809$/ { in_block=1 }
	in_block && /^endef$/ {
		print
		print ""
		print "define U-Boot/easepi-rk3568-uart2-115200"
		print "  \$(U-Boot/rk3568/Default)"
		print "  NAME:=Easepi RK3568 UART2 115200"
		print "  TPL:=rk3568_ddr_1560MHz_uart2_m0_115200_v1.21.bin"
		print "  DEPENDS:=+PACKAGE_u-boot-\$(1):trusted-firmware-a-rk3568-e25"
		print "  UBOOT_CONFIG:=easepi-rk3568-uart2-115200"
		print "  DEFAULT:=y"
		print "endef"
		in_block=0
		next
	}
	{ print }
	' "$UBOOT_MK" > "$UBOOT_MK.tmp" && mv "$UBOOT_MK.tmp" "$UBOOT_MK"

	awk '/^  easepi-rk3568-rk809 \\$/{ print; print "  easepi-rk3568-uart2-115200 \\"; next }1' "$UBOOT_MK" > "$UBOOT_MK.tmp" && mv "$UBOOT_MK.tmp" "$UBOOT_MK"
	echo "==> uboot-rockchip/Makefile 已注册 easepi-rk3568-uart2-115200"
else
	echo "==> uboot-rockchip/Makefile 已存在 115200 变体或文件不存在，跳过"
fi

# --- legacy.mk 追加/刷新 K50S / K50S MAX 设备定义 ---
# 先删除旧定义（如有），再统一追加带 115200 U-Boot / bootscript 覆盖的新定义。
if [ -f "${MK_FILE}" ]; then
	sed -i '/^define Device\/roceos_k50s$/,/^TARGET_DEVICES += roceos_k50s$/d' "${MK_FILE}"
	sed -i '/^define Device\/roceos_k50s_max$/,/^TARGET_DEVICES += roceos_k50s_max$/d' "${MK_FILE}"

	cat >> "${MK_FILE}" << 'MK_EOF'

define Device/roceos_k50s
  $(call Device/Legacy/rk3568,$(1))
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S
  DEVICE_DTS := rk3568/rk3568-roceos-k50s
  UBOOT_DEVICE_NAME := easepi-rk3568-uart2-115200
  BOOT_SCRIPT := rk3568-uart2-115200
  DEVICE_PACKAGES += kmod-r8125 kmod-thermal kmod-hwmon-pwmfan kmod-usb-storage kmod-usb-storage-uas kmod-nvme kmod-ata-ahci kmod-brcmfmac brcmfmac-firmware-43455-sdio wpad-basic-mbedtls
endef
TARGET_DEVICES += roceos_k50s

define Device/roceos_k50s_max
  $(call Device/Legacy/rk3568,$(1))
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S MAX
  DEVICE_DTS := rk3568/rk3568-roceos-k50s-max
  UBOOT_DEVICE_NAME := easepi-rk3568-uart2-115200
  BOOT_SCRIPT := rk3568-uart2-115200
  DEVICE_PACKAGES += kmod-r8125 kmod-thermal kmod-hwmon-pwmfan kmod-usb-storage kmod-usb-storage-uas kmod-nvme kmod-ata-ahci kmod-brcmfmac brcmfmac-firmware-43455-sdio wpad-basic-mbedtls
endef
TARGET_DEVICES += roceos_k50s_max
MK_EOF
	echo "==> legacy.mk 已刷新 ROCEOS K50S / K50S MAX 设备定义（115200）"
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
