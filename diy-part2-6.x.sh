#!/bin/bash
# ============================================================
# iStoreOS 24.10 ROCEOS K50S 云编译 DIY 脚本
# 对齐原始仓库工作流：DTS 放 target/linux/rockchip/dts/rk3568/
# ============================================================

set -e

echo "==================== K50S 适配开始 ===================="

# --------------------------------------------------
# 步骤1: 写入 DTS/DTSI 到 target/linux/rockchip/dts/rk3568/
# 和 nsy_g68-plus 等设备保持一致
# --------------------------------------------------
DTS_DIR="target/linux/rockchip/dts/rk3568"
mkdir -p "${DTS_DIR}"

# --- 写入 rk3568-roceos-k50s.dtsi ---
cat > "${DTS_DIR}/rk3568-roceos-k50s.dtsi" << 'DTSI_EOF'
// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/*
 * Copyright (c) 2020 Rockchip Electronics Co., Ltd.
 * Copyright (c) 2022 ROCEOS
 */

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/pinctrl/rockchip.h>
#include <dt-bindings/pwm/pwm.h>
#include <dt-bindings/input/rk-input.h>
#include "rk3568.dtsi"

/ {
	model = "ROCEOS K50S";
	compatible = "roceos,k50s", "rockchip,rk3568";

	aliases {
		ethernet0 = &gmac0;
		ethernet1 = &gmac1;
		mmc0 = &sdmmc0;
		mmc1 = &sdhci;
	};

	chosen: chosen {
		bootargs = "earlycon=uart8250,mmio32,0xfe660000 console=ttyFIQ0 root=PARTUUID=614e0000-0000 rootfstype=squashfs,ext4";
	};

	fiq-debugger {
		compatible = "rockchip,fiq-debugger";
		rockchip,serial-id = <2>;
		rockchip,wake-irq = <0>;
		rockchip,irq-mode-enable = <1>;
		rockchip,baudrate = <115200>;
		interrupts = <GIC_SPI 252 IRQ_TYPE_LEVEL_LOW>;
		pinctrl-names = "default";
		pinctrl-0 = <&uart2m0_xfer>;
		status = "okay";
	};

	adc_keys: adc-keys {
		compatible = "adc-keys";
		io-channels = <&saradc 0>;
		io-channel-names = "buttons";
		keyup-threshold-microvolt = <1800000>;
		poll-interval = <100>;
		recovery-key {
			label = "Recovery";
			linux,code = <KEY_VENDOR>;
			press-threshold-microvolt = <1800>;
		};
	};

	gpio-keys {
		compatible = "gpio-keys";
		pinctrl-names = "default";
		pinctrl-0 = <&reset_button>;
		button@1 {
			label = "reset_button";
			linux,code = <KEY_RESTART>;
			gpios = <&gpio0 RK_PA0 GPIO_ACTIVE_LOW>;
			linux,input-type = <1>;
			debounce-interval = <60>;
		};
	};

	sdio_pwrseq: sdio-pwrseq {
		compatible = "mmc-pwrseq-simple";
		clocks = <&rk809 1>;
		clock-names = "ext_clock";
		pinctrl-names = "default";
		pinctrl-0 = <&wifi_enable_h>;
		post-power-on-delay-ms = <200>;
		reset-gpios = <&gpio3 RK_PD5 GPIO_ACTIVE_LOW>;
	};

	wireless_wlan: wireless-wlan {
		compatible = "wlan-platdata";
		rockchip,grf = <&grf>;
		wifi_chip_type = "ap6255";
		WIFI,poweren_gpio = <&gpio3 RK_PD5 GPIO_ACTIVE_HIGH>;
		status = "okay";
	};

	wireless_bluetooth: wireless-bluetooth {
		compatible = "bluetooth-platdata";
		clocks = <&rk809 1>;
		clock-names = "ext_clock";
		uart_rts_gpios = <&gpio2 RK_PB1 GPIO_ACTIVE_LOW>;
		pinctrl-names = "default", "rts_gpio";
		pinctrl-0 = <&uart8m0_rtsn>;
		pinctrl-1 = <&uart8_gpios>;
		BT,reset_gpio    = <&gpio3 RK_PA0 GPIO_ACTIVE_HIGH>;
		BT,wake_gpio     = <&gpio3 RK_PA1 GPIO_ACTIVE_HIGH>;
		BT,wake_host_irq = <&gpio3 RK_PA2 GPIO_ACTIVE_HIGH>;
		status = "okay";
	};

	leds {
		compatible = "gpio-leds";
		pinctrl-names = "default";
		pinctrl-0 = <&led_green_en>;
		led_green: green {
			gpios = <&gpio2 RK_PD7 GPIO_ACTIVE_HIGH>;
			label = "green:sys";
			linux,default-trigger = "heartbeat";
		};
	};

	dc_12v: dc-12v {
		compatible = "regulator-fixed";
		regulator-name = "dc_12v";
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <12000000>;
		regulator-max-microvolt = <12000000>;
	};

	vcc5v0_sys: vcc5v0-sys {
		compatible = "regulator-fixed";
		regulator-name = "vcc5v0_sys";
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <5000000>;
		regulator-max-microvolt = <5000000>;
		vin-supply = <&dc_12v>;
	};

	vcc3v3_sys: vcc3v3-sys {
		compatible = "regulator-fixed";
		regulator-name = "vcc3v3_sys";
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <3300000>;
		regulator-max-microvolt = <3300000>;
		enable-active-high;
		gpio = <&gpio0 RK_PB6 GPIO_ACTIVE_HIGH>;
		pinctrl-names = "default";
		pinctrl-0 = <&vcc3v3_sys_en>;
		vin-supply = <&vcc5v0_sys>;
	};

	vcc5v0_otg: vcc5v0-otg-regulator {
		compatible = "regulator-fixed";
		regulator-name = "vcc5v0_otg";
		regulator-min-microvolt = <5000000>;
		regulator-max-microvolt = <5000000>;
		enable-active-high;
		gpio = <&gpio0 RK_PA5 GPIO_ACTIVE_HIGH>;
		vin-supply = <&vcc5v0_sys>;
		pinctrl-names = "default";
		pinctrl-0 = <&vcc5v0_otg_en>;
	};

	pcie30_avdd0v9: pcie30-avdd0v9 {
		compatible = "regulator-fixed";
		regulator-name = "pcie30_avdd0v9";
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <900000>;
		regulator-max-microvolt = <900000>;
		vin-supply = <&vcc3v3_sys>;
	};

	pcie30_avdd1v8: pcie30-avdd1v8 {
		compatible = "regulator-fixed";
		regulator-name = "pcie30_avdd1v8";
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <1800000>;
		regulator-max-microvolt = <1800000>;
		vin-supply = <&vcc3v3_sys>;
	};

	vcc3v3_pcie: vcc3v3-pcie {
		compatible = "regulator-fixed";
		regulator-name = "vcc3v3_pcie";
		regulator-min-microvolt = <3300000>;
		regulator-max-microvolt = <3300000>;
		enable-active-high;
		gpio = <&gpio0 RK_PC4 GPIO_ACTIVE_HIGH>;
		startup-delay-us = <5000>;
		vin-supply = <&vcc5v0_sys>;
	};

	fan: fan {
		compatible = "pwm-fan";
		#cooling-cells = <2>;
		pwms = <&pwm0 0 50000>;
		cooling-levels = <0 50 100 150 200 255>;
		status = "okay";
	};
};

&cpu0 { cpu-supply = <&vdd_cpu>; };
&cpu1 { cpu-supply = <&vdd_cpu>; };
&cpu2 { cpu-supply = <&vdd_cpu>; };
&cpu3 { cpu-supply = <&vdd_cpu>; };

&gpu {
	mali-supply = <&vdd_gpu>;
	status = "okay";
};

&pmu_io_domains {
	status = "okay";
	pmuio1-supply = <&vcc3v3_pmu>;
	pmuio2-supply = <&vcc3v3_pmu>;
	vccio1-supply = <&vccio_acodec>;
	vccio3-supply = <&vccio_sd>;
	vccio4-supply = <&vcc_3v3>;
	vccio5-supply = <&vcc_3v3>;
	vccio6-supply = <&vcc_1v8>;
	vccio7-supply = <&vcc_3v3>;
};

&display_subsystem { status = "disabled"; };
&hdmi { status = "disabled"; };
&hdmi_in_vp0 { status = "disabled"; };
&hdmi_in_vp1 { status = "disabled"; };
&route_hdmi { status = "disabled"; };
&codec { status = "okay"; };
&i2s0_8ch { status = "okay"; };
&rkcif { status = "disabled"; };
&rkcif_mmu { status = "disabled"; };
&rkisp { status = "disabled"; };
&rkisp_mmu { status = "disabled"; };
&isp0_mmu { status = "disabled"; };
&isp1_mmu { status = "disabled"; };

&usb_host0_ehci { status = "okay"; };
&usb_host0_ohci { status = "okay"; };
&usb_host1_ehci { status = "okay"; };
&usb_host1_ohci { status = "okay"; };
&usb2phy0 { status = "okay"; };
&usb2phy1 { status = "okay"; };
&combphy0_usbc { status = "okay"; };
&combphy1_usbc { status = "okay"; };
&combphy2_psq { status = "okay"; };

&pcie2x1 {
	reset-gpios = <&gpio3 RK_PA5 GPIO_ACTIVE_HIGH>;
	vpcie3v3-supply = <&vcc3v3_pcie>;
	status = "okay";
};

&pcie3x1 {
	rockchip,bifurcation;
	reset-gpios = <&gpio3 RK_PA3 GPIO_ACTIVE_HIGH>;
	vpcie3v3-supply = <&vcc3v3_pcie>;
	status = "okay";
};

&pcie3x2 {
	compatible = "rockchip,rk3568-pcie", "snps,dw-pcie";
	reset-gpios = <&gpio3 RK_PA4 GPIO_ACTIVE_HIGH>;
	vpcie3v3-supply = <&vcc3v3_pcie>;
	status = "okay";
};

&pcie30phy { status = "okay"; };

&pinctrl {
	leds {
		led_green_en: led-green-en {
			rockchip,pins = <2 RK_PD7 RK_FUNC_GPIO &pcfg_pull_none>;
		};
	};
	keys {
		reset_button: reset-button {
			rockchip,pins = <0 RK_PA0 RK_FUNC_GPIO &pcfg_pull_up>;
		};
	};
	pmic {
		pmic_int: pmic_int {
			rockchip,pins = <0 RK_PA3 RK_FUNC_GPIO &pcfg_pull_up>;
		};
		soc_slppin_gpio: soc_slppin_gpio {
			rockchip,pins = <0 RK_PA2 RK_FUNC_GPIO &pcfg_output_low_pull_down>;
		};
		soc_slppin_slp: soc_slppin_slp {
			rockchip,pins = <0 RK_PA2 1 &pcfg_pull_up>;
		};
		soc_slppin_rst: soc_slppin_rst {
			rockchip,pins = <0 RK_PA2 2 &pcfg_pull_none>;
		};
	};
	usb {
		vcc5v0_otg_en: vcc5v0-otg-en {
			rockchip,pins = <0 RK_PA5 RK_FUNC_GPIO &pcfg_pull_none>;
		};
	};
	vcc {
		vcc3v3_sys_en: vcc3v3-sys-en {
			rockchip,pins = <0 RK_PB6 RK_FUNC_GPIO &pcfg_pull_none>;
		};
	};
	wireless-wlan {
		wifi_host_wake_irq: wifi-host-wake-irq {
			rockchip,pins = <3 RK_PD4 RK_FUNC_GPIO &pcfg_pull_down>;
		};
	};
	sdio-pwrseq {
		wifi_enable_h: wifi-enable-h {
			rockchip,pins = <3 RK_PD5 RK_FUNC_GPIO &pcfg_pull_none>;
		};
	};
	wireless-bluetooth {
		uart8_gpios: uart8-gpios {
			rockchip,pins = <2 RK_PB1 RK_FUNC_GPIO &pcfg_pull_none>;
		};
	};
	gmac0 {
		gmac0_clkinout: gmac0-clkinout {
			rockchip,pins = <2 RK_PC4 2 &pcfg_pull_none>;
		};
	};
	gmac1 {
		eth1m1_pins: eth1m1-pins {
			rockchip,pins = <3 RK_PA7 RK_FUNC_GPIO &pcfg_pull_up>,
					<3 RK_PA6 RK_FUNC_GPIO &pcfg_pull_up>;
		};
		gmac1m1_clkinout: gmac1m1-clkinout {
			rockchip,pins = <2 RK_PD0 2 &pcfg_pull_none>;
		};
	};
};

&saradc {
	status = "okay";
	vref-supply = <&vcca_1v8>;
};

&sdhci {
	bus-width = <8>;
	supports-emmc;
	non-removable;
	max-frequency = <200000000>;
	status = "okay";
};

&sdmmc0 {
	max-frequency = <150000000>;
	supports-sd;
	bus-width = <4>;
	cap-mmc-highspeed;
	cap-sd-highspeed;
	disable-wp;
	sd-uhs-sdr104;
	vmmc-supply = <&vcc3v3_sd>;
	vqmmc-supply = <&vccio_sd>;
	pinctrl-names = "default";
	pinctrl-0 = <&sdmmc0_bus4 &sdmmc0_clk &sdmmc0_cmd &sdmmc0_det>;
	status = "okay";
};

&sdmmc2 {
	max-frequency = <150000000>;
	supports-sdio;
	bus-width = <4>;
	disable-wp;
	cap-sd-highspeed;
	cap-sdio-irq;
	keep-power-in-suspend;
	mmc-pwrseq = <&sdio_pwrseq>;
	non-removable;
	pinctrl-names = "default";
	pinctrl-0 = <&sdmmc2m0_bus4 &sdmmc2m0_cmd &sdmmc2m0_clk>;
	sd-uhs-sdr104;
	status = "okay";
};

&sata0 { status = "okay"; };

&tsadc {
	rockchip,hw-tshut-mode = <0>;
	rockchip,hw-tshut-polarity = <0>;
	status = "okay";
};

&rng { status = "okay"; };
&otp { status = "okay"; };
&crypto { status = "okay"; };
&ppmu { status = "okay"; };
&dfi { status = "okay"; };

&i2c0 {
	status = "okay";
	i2c-scl-rising-time-ns = <160>;
	i2c-scl-falling-time-ns = <30>;
	clock-frequency = <400000>;

	vdd_cpu: tcs4525@1c {
		compatible = "tcs,tcs452x";
		reg = <0x1c>;
		vin-supply = <&vcc3v3_sys>;
		regulator-compatible = "fan53555-reg";
		regulator-name = "vdd_cpu";
		regulator-min-microvolt = <712500>;
		regulator-max-microvolt = <1390000>;
		regulator-init-microvolt = <900000>;
		regulator-ramp-delay = <2300>;
		fcs,suspend-voltage-selector = <1>;
		regulator-boot-on;
		regulator-always-on;
		regulator-state-mem {
			regulator-off-in-suspend;
		};
	};

	rk809: pmic@20 {
		compatible = "rockchip,rk809";
		reg = <0x20>;
		interrupt-parent = <&gpio0>;
		interrupts = <3 IRQ_TYPE_LEVEL_LOW>;

		pinctrl-names = "default", "pmic-sleep", "pmic-power-off", "pmic-reset";
		pinctrl-0 = <&pmic_int>;
		pinctrl-1 = <&soc_slppin_slp>, <&rk817_slppin_slp>;
		pinctrl-2 = <&soc_slppin_gpio>, <&rk817_slppin_pwrdn>;
		pinctrl-3 = <&soc_slppin_gpio>, <&rk817_slppin_rst>;

		rockchip,system-power-controller;
		wakeup-source;
		#clock-cells = <1>;
		clock-output-names = "rk808-clkout1", "rk808-clkout2";
		pmic-reset-func = <0>;
		not-save-power-en = <1>;

		vcc1-supply = <&vcc3v3_sys>;
		vcc2-supply = <&vcc3v3_sys>;
		vcc3-supply = <&vcc3v3_sys>;
		vcc4-supply = <&vcc3v3_sys>;
		vcc5-supply = <&vcc3v3_sys>;
		vcc6-supply = <&vcc3v3_sys>;
		vcc7-supply = <&vcc3v3_sys>;
		vcc8-supply = <&vcc3v3_sys>;
		vcc9-supply = <&vcc3v3_sys>;

		pwrkey {
			status = "okay";
		};

		pinctrl_rk8xx: pinctrl_rk8xx {
			gpio-controller;
			#gpio-cells = <2>;

			rk817_slppin_null: rk817_slppin_null {
				pins = "gpio_slp";
				function = "pin_fun0";
			};

			rk817_slppin_slp: rk817_slppin_slp {
				pins = "gpio_slp";
				function = "pin_fun1";
			};

			rk817_slppin_pwrdn: rk817_slppin_pwrdn {
				pins = "gpio_slp";
				function = "pin_fun2";
			};

			rk817_slppin_rst: rk817_slppin_rst {
				pins = "gpio_slp";
				function = "pin_fun3";
			};
		};

		regulators {
			vdd_logic: DCDC_REG1 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <500000>;
				regulator-max-microvolt = <1350000>;
				regulator-init-microvolt = <900000>;
				regulator-ramp-delay = <6001>;
				regulator-initial-mode = <0x2>;
				regulator-name = "vdd_logic";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vdd_gpu: DCDC_REG2 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <500000>;
				regulator-max-microvolt = <1350000>;
				regulator-init-microvolt = <900000>;
				regulator-ramp-delay = <6001>;
				regulator-initial-mode = <0x2>;
				regulator-name = "vdd_gpu";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcc_ddr: DCDC_REG3 {
				regulator-always-on;
				regulator-boot-on;
				regulator-initial-mode = <0x2>;
				regulator-name = "vcc_ddr";
				regulator-state-mem {
					regulator-on-in-suspend;
				};
			};

			vdd_npu: DCDC_REG4 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <500000>;
				regulator-max-microvolt = <1350000>;
				regulator-init-microvolt = <900000>;
				regulator-ramp-delay = <6001>;
				regulator-initial-mode = <0x2>;
				regulator-name = "vdd_npu";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vdda0v9_image: LDO_REG1 {
				regulator-boot-on;
				regulator-always-on;
				regulator-min-microvolt = <900000>;
				regulator-max-microvolt = <900000>;
				regulator-name = "vdda0v9_image";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vdda_0v9: LDO_REG2 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <900000>;
				regulator-max-microvolt = <900000>;
				regulator-name = "vdda_0v9";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vdda0v9_pmu: LDO_REG3 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <900000>;
				regulator-max-microvolt = <900000>;
				regulator-name = "vdda0v9_pmu";
				regulator-state-mem {
					regulator-on-in-suspend;
					regulator-suspend-microvolt = <900000>;
				};
			};

			vccio_acodec: LDO_REG4 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <3300000>;
				regulator-max-microvolt = <3300000>;
				regulator-name = "vccio_acodec";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vccio_sd: LDO_REG5 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <1800000>;
				regulator-max-microvolt = <3300000>;
				regulator-name = "vccio_sd";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcc3v3_pmu: LDO_REG6 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <3300000>;
				regulator-max-microvolt = <3300000>;
				regulator-name = "vcc3v3_pmu";
				regulator-state-mem {
					regulator-on-in-suspend;
					regulator-suspend-microvolt = <3300000>;
				};
			};

			vcca_1v8: LDO_REG7 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <1800000>;
				regulator-max-microvolt = <1800000>;
				regulator-name = "vcca_1v8";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcca1v8_pmu: LDO_REG8 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <1800000>;
				regulator-max-microvolt = <1800000>;
				regulator-name = "vcca1v8_pmu";
				regulator-state-mem {
					regulator-on-in-suspend;
					regulator-suspend-microvolt = <1800000>;
				};
			};

			vcca1v8_image: LDO_REG9 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <1800000>;
				regulator-max-microvolt = <1800000>;
				regulator-name = "vcca1v8_image";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcc_1v8: DCDC_REG5 {
				regulator-always-on;
				regulator-boot-on;
				regulator-min-microvolt = <1800000>;
				regulator-max-microvolt = <1800000>;
				regulator-name = "vcc_1v8";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcc_3v3: SWITCH_REG1 {
				regulator-always-on;
				regulator-boot-on;
				regulator-name = "vcc_3v3";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};

			vcc3v3_sd: SWITCH_REG2 {
				regulator-always-on;
				regulator-boot-on;
				regulator-name = "vcc3v3_sd";
				regulator-state-mem {
					regulator-off-in-suspend;
				};
			};
		};

		rk809_codec: codec {
			#sound-dai-cells = <1>;
			compatible = "rockchip,rk809-codec", "rockchip,rk817-codec";
			clocks = <&cru I2S1_MCLKOUT>;
			clock-names = "mclk";
			assigned-clocks = <&cru I2S1_MCLKOUT>, <&cru I2S1_MCLK_TX_IOE>;
			assigned-clock-rates = <12288000>;
			assigned-clock-parents = <&cru I2S1_MCLKOUT_TX>, <&cru I2S1_MCLKOUT_TX>;
			pinctrl-names = "default";
			pinctrl-0 = <&i2s1m0_mclk>;
			hp-volume = <20>;
			spk-volume = <3>;
			mic-in-differential;
			status = "okay";
		};
	};
};

&i2c5 {
	status = "okay";
	i2c-scl-rising-time-ns = <160>;
	i2c-scl-falling-time-ns = <30>;
	clock-frequency = <400000>;
};

&i2s0_8ch {
	status = "okay";
};

&i2s1_8ch {
	status = "okay";
	rockchip,clk-trcm = <1>;
	pinctrl-names = "default";
	pinctrl-0 = <&i2s1m0_sclktx &i2s1m0_lrcktx &i2s1m0_sdi0 &i2s1m0_sdo0>;
};

&pwm0 {
	status = "okay";
};

&uart0 {
	status = "okay";
	pinctrl-names = "default";
	pinctrl-0 = <&uart0_xfer &uart0_cts &uart0_rts>;
};

&uart8 {
	status = "okay";
	pinctrl-names = "default";
	pinctrl-0 = <&uart8m0_xfer &uart8m0_ctsn &uart8m0_rtsn>;
};

&spi0 {
	status = "okay";
	pinctrl-names = "default";
	pinctrl-0 = <&spi0m1_pins>;
};

&spi1 {
	status = "okay";
	pinctrl-names = "default";
	pinctrl-0 = <&spi1m1_pins>;
};

&rknpu {
	rknpu-supply = <&vdd_npu>;
	status = "okay";
};

&rknpu_mmu {
	status = "okay";
};

&rockchip_suspend {
	status = "okay";
};

&reserved_memory {
	linux,cma {
		compatible = "shared-dma-pool";
		inactive;
		reusable;
		reg = <0x0 0x10000000 0x0 0x00800000>;
		linux,cma-default;
	};

	ramoops: ramoops@110000 {
		compatible = "ramoops";
		reg = <0x0 0x110000 0x0 0xf0000>;
		record-size = <0x20000>;
		console-size = <0x80000>;
		ftrace-size = <0x00000>;
		pmsg-size = <0x50000>;
	};
};
DTSI_EOF

# --- 写入 rk3568-roceos-k50s.dts ---
cat > "${DTS_DIR}/rk3568-roceos-k50s.dts" << 'DTS_EOF'
// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/*
 * Copyright (c) 2020 Rockchip Electronics Co., Ltd.
 * Copyright (c) 2022 ROCEOS
 */

/dts-v1/;

#include "rk3568-roceos-k50s.dtsi"

/ {
	model = "ROCEOS K50S";
	compatible = "roceos,k50s", "rockchip,rk3568", "gmac_1v8";
	eth_order = "0001:11:00.0,0002:21:00.0,0000:01:00.0,fe010000.ethernet,fe2a0000.ethernet";
	kdebug = "0";
	hwmodel_id = "K50S";
	eth_driver = "r8125";
	hw_support = "hdmi,2.5g";

	aliases {
		ethernet0 = &gmac0;
		ethernet1 = &gmac1;
	};
};

&gmac0 {
	phy-mode = "rgmii";
	clock_in_out = "input";
	snps,reset-gpio = <&gpio2 RK_PD3 GPIO_ACTIVE_LOW>;
	snps,reset-active-low;
	snps,reset-delays-us = <0 20000 100000>;
	assigned-clocks = <&cru SCLK_GMAC0_RX_TX>, <&cru SCLK_GMAC0>;
	assigned-clock-parents = <&cru SCLK_GMAC0_RGMII_SPEED>, <&gmac0_clkin>;
	assigned-clock-rates = <0>, <125000000>, <25000000>;
	pinctrl-names = "default";
	pinctrl-0 = <&gmac0_miim
		     &gmac0_tx_bus2
		     &gmac0_rx_bus2
		     &gmac0_rgmii_clk
		     &gmac0_rgmii_bus
		     &gmac0_clkinout>;
	tx_delay = <0x3c>;
	rx_delay = <0x2f>;
	phy-handle = <&rgmii_phy0>;
	status = "okay";
};

&mdio0 {
	rgmii_phy0: phy@0 {
		compatible = "ethernet-phy-ieee802.3-c22";
		reg = <0x0>;
		realtek,fiber;
		realtek,led-data = <0x616b>;
	};
};

&gmac1 {
	phy-mode = "rgmii";
	clock_in_out = "input";
	snps,reset-gpio = <&gpio2 RK_PD5 GPIO_ACTIVE_LOW>;
	snps,reset-active-low;
	snps,reset-delays-us = <0 20000 100000>;
	assigned-clocks = <&cru SCLK_GMAC1_RX_TX>, <&cru SCLK_GMAC1>, <&cru CLK_MAC1_OUT>;
	assigned-clock-parents = <&cru SCLK_GMAC1_RGMII_SPEED>, <&gmac1_clkin>;
	assigned-clock-rates = <0>, <125000000>, <25000000>;
	pinctrl-names = "default";
	pinctrl-0 = <&gmac1m1_miim
		     &gmac1m1_tx_bus2
		     &gmac1m1_rx_bus2
		     &gmac1m1_rgmii_clk
		     &gmac1m1_rgmii_bus
		     &eth1m1_pins
		     &gmac1m1_clkinout>;
	tx_delay = <0x4f>;
	rx_delay = <0x26>;
	phy-handle = <&rgmii_phy1>;
	status = "okay";
};

&mdio1 {
	rgmii_phy1: phy@0 {
		compatible = "ethernet-phy-ieee802.3-c22";
		reg = <0x0>;
		realtek,fiber;
		realtek,led-data = <0x616b>;
	};
};

&sata0 {
	status = "okay";
};

&sdio_pwrseq {
	status = "okay";
	reset-gpios = <&gpio3 RK_PD5 GPIO_ACTIVE_LOW>;
	post-power-on-delay-ms = <200>;
};

&wireless_wlan {
	pinctrl-names = "default";
	pinctrl-0 = <&wifi_host_wake_irq>;
	WIFI,host_wake_irq = <&gpio3 RK_PD4 GPIO_ACTIVE_HIGH>;
	wifi_chip_type = "ap6255";
	status = "okay";
};

&wireless_bluetooth {
	compatible = "bluetooth-platdata";
	clocks = <&rk809 1>;
	clock-names = "ext_clock";
	uart_rts_gpios = <&gpio2 RK_PB1 GPIO_ACTIVE_LOW>;
	pinctrl-names = "default", "rts_gpio";
	pinctrl-0 = <&uart8m0_rtsn>;
	pinctrl-1 = <&uart8_gpios>;
	BT,reset_gpio    = <&gpio4 RK_PC4 GPIO_ACTIVE_HIGH>;
	BT,wake_gpio     = <&gpio0 RK_PD5 GPIO_ACTIVE_HIGH>;
	BT,wake_host_irq = <&gpio0 RK_PD4 GPIO_ACTIVE_HIGH>;
	status = "okay";
};

&sdmmc2 {
	max-frequency = <150000000>;
	supports-sdio;
	bus-width = <4>;
	disable-wp;
	cap-sd-highspeed;
	cap-sdio-irq;
	keep-power-in-suspend;
	mmc-pwrseq = <&sdio_pwrseq>;
	non-removable;
	pinctrl-names = "default";
	pinctrl-0 = <&sdmmc2m0_bus4 &sdmmc2m0_cmd &sdmmc2m0_clk>;
	sd-uhs-sdr104;
	status = "okay";
};
DTS_EOF

echo "==> DTS 已写入 ${DTS_DIR}"
ls -la "${DTS_DIR}/rk3568-roceos-k50s"*

# --------------------------------------------------
# 步骤2: 修改 armv8.mk 添加 K50S 设备定义
# 关键修正：添加 DEVICE_DTS_DIR := ../dts
# --------------------------------------------------
MK_FILE="target/linux/rockchip/image/armv8.mk"

if [ -f "${MK_FILE}" ]; then
	if ! grep -q "roceos_k50s" "${MK_FILE}"; then
		cat >> "${MK_FILE}" << 'MK_EOF'

define Device/roceos_k50s
  DEVICE_VENDOR := ROCEOS
  DEVICE_MODEL := K50S
  SOC := rk3568
  DEVICE_DTS := rk3568/rk3568-roceos-k50s
  DEVICE_DTS_DIR := ../dts
  UBOOT_DEVICE_NAME := rk3568-roceos-k50s
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-img | gzip | append-metadata
  DEVICE_PACKAGES := kmod-r8125 kmod-thermal kmod-hwmon-pwmfan kmod-leds-gpio \
    kmod-gpio-button-hotplug kmod-usb-net-cdc-ether kmod-usb-net-rndis \
    kmod-usb-storage kmod-usb-storage-uas kmod-nvme kmod-ata-ahci \
    kmod-sound-core kmod-sound-soc-rockchip kmod-brcmfmac \
    brcmfmac-firmware-43430b0 wpad-basic-mbedtls
endef
TARGET_DEVICES += roceos_k50s
MK_EOF
		echo "==> armv8.mk 已添加 K50S 设备定义"
	else
		echo "==> armv8.mk 已存在 K50S，跳过"
	fi
else
	echo "警告: 未找到 ${MK_FILE}"
fi

# --------------------------------------------------
# 步骤3: 修改 01_network
# --------------------------------------------------
NETWORK_FILE="target/linux/rockchip/armv8/base-files/etc/board.d/01_network"
if [ -f "${NETWORK_FILE}" ] && ! grep -q "roceos,k50s" "${NETWORK_FILE}"; then
    TMP_FILE=$(mktemp)
    awk '
        /esac/ && !done {
            print "\troceos,k50s|"
            print "\t\tucidef_set_interfaces_lan_wan \"eth1 eth2 eth3 eth4\" \"eth0\""
            done=1
        }
        {print}
    ' "${NETWORK_FILE}" > "${TMP_FILE}"
    mv "${TMP_FILE}" "${NETWORK_FILE}"
    chmod +x "${NETWORK_FILE}"
    echo "==> 01_network 已添加 K50S"
else
    echo "==> 01_network 已存在 K50S 或文件不存在"
fi

# --------------------------------------------------
# 步骤4: 更新 .config
# --------------------------------------------------
echo "==> 更新 .config ..."

CONFIG_LINES=(
    "CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_roceos_k50s=y"
    "CONFIG_PACKAGE_kmod-r8125=y"
    "CONFIG_PACKAGE_kmod-nvme=y"
    "CONFIG_PACKAGE_kmod-ata-ahci=y"
    "CONFIG_PACKAGE_kmod-sata-ahci=y"
    "CONFIG_PACKAGE_kmod-thermal=y"
    "CONFIG_PACKAGE_kmod-hwmon-pwmfan=y"
    "CONFIG_PACKAGE_kmod-leds-gpio=y"
    "CONFIG_PACKAGE_kmod-gpio-button-hotplug=y"
    "CONFIG_PACKAGE_kmod-brcmfmac=y"
    "CONFIG_PACKAGE_brcmfmac-firmware-43430b0=y"
    "CONFIG_PACKAGE_wpad-basic-mbedtls=y"
    "CONFIG_PACKAGE_kmod-usb-storage=y"
    "CONFIG_PACKAGE_kmod-usb-storage-uas=y"
    "CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
    "CONFIG_PACKAGE_kmod-usb-net-rndis=y"
)

for line in "${CONFIG_LINES[@]}"; do
    key=$(echo "$line" | cut -d= -f1)
    if ! grep -q "^${key}=y" .config 2>/dev/null; then
        echo "$line" >> .config
    fi
done
echo "==> .config 已更新"

echo "==================== K50S 适配完成 ===================="
