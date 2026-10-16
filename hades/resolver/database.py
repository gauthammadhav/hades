"""HADES Hardware Database.

Contains known USB Vendor:Product ID definitions, classification categories,
default SDK toolchains, and isolation recommendations.
"""

from typing import Dict, Optional, Tuple
from hades.models.device import (
    DeviceClassification,
    IsolationRecommendation,
)


class HardwareEntry:
    """Entry describing a hardware device in the database."""
    def __init__(
        self,
        vendor_id: str,
        product_id: str,
        name: str,
        classification: DeviceClassification,
        target_board: Optional[str] = None,
        target_chip: Optional[str] = None,
        recommended_sdk: Optional[str] = None,
        isolation: IsolationRecommendation = IsolationRecommendation.CONTAINER_BROKER,
        kernel_module_required: bool = False,
        description: str = "",
    ):
        self.vendor_id = vendor_id.lower()
        self.product_id = product_id.lower()
        self.name = name
        self.classification = classification
        self.target_board = target_board
        self.target_chip = target_chip
        self.recommended_sdk = recommended_sdk
        self.isolation = isolation
        self.kernel_module_required = kernel_module_required
        self.description = description

    @property
    def vid_pid(self) -> str:
        return f"{self.vendor_id}:{self.product_id}"


HARDWARE_DATABASE: Dict[str, HardwareEntry] = {
    # =========================================================================
    # STAGE 1: NATIVE MICROCONTROLLERS (Direct Descriptors -> SDK Match)
    # =========================================================================
    # Espressif Native USB
    "303a:1001": HardwareEntry(
        vendor_id="303a",
        product_id="1001",
        name="Espressif ESP32-S3/C3/C6 (Built-in USB-JTAG/Serial)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="ESP32-S3-DevKitC-1",
        target_chip="ESP32-S3",
        recommended_sdk="esp-idf",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Native Espressif USB-JTAG and Serial device controller"
    ),
    "303a:0002": HardwareEntry(
        vendor_id="303a",
        product_id="0002",
        name="Espressif ESP32-S2 (USB CDC Mode)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="ESP32-S2-Saola-1",
        target_chip="ESP32-S2",
        recommended_sdk="esp-idf",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Espressif ESP32-S2 USB CDC peripheral"
    ),
    "303a:1002": HardwareEntry(
        vendor_id="303a",
        product_id="1002",
        name="Espressif ESP32-C3 (USB CDC Mode)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="ESP32-C3-DevKitM-1",
        target_chip="ESP32-C3",
        recommended_sdk="esp-idf",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Espressif ESP32-C3 USB CDC peripheral"
    ),

    # Raspberry Pi RP2040 / RP2350
    "2e8a:0003": HardwareEntry(
        vendor_id="2e8a",
        product_id="0003",
        name="Raspberry Pi Pico (RP2040 USB Serial)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Raspberry Pi Pico",
        target_chip="RP2040",
        recommended_sdk="pico-sdk",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Native RP2040 USB Serial endpoint running MicroPython or Pico C SDK"
    ),
    "2e8a:0005": HardwareEntry(
        vendor_id="2e8a",
        product_id="0005",
        name="Raspberry Pi Pico (RP2040 Bootloader ROM)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Raspberry Pi Pico (Bootloader)",
        target_chip="RP2040",
        recommended_sdk="picotool",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="RP2040 BOOTSEL mass storage / UF2 flashing mode"
    ),
    "2e8a:000a": HardwareEntry(
        vendor_id="2e8a",
        product_id="000a",
        name="Raspberry Pi Pico 2 (RP2350 USB Serial)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Raspberry Pi Pico 2",
        target_chip="RP2350",
        recommended_sdk="pico-sdk",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Native RP2350 Dual Arm Cortex-M33 / Hazard3 RISC-V controller"
    ),

    # Arduino Official Native USB Boards
    "2341:0043": HardwareEntry(
        vendor_id="2341",
        product_id="0043",
        name="Arduino Uno R3 (ATmega16U2 Serial)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Arduino Uno R3",
        target_chip="ATmega328P",
        recommended_sdk="arduino-cli",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Official Arduino Uno Rev 3 with onboard 16U2 USB transceiver"
    ),
    "2341:0036": HardwareEntry(
        vendor_id="2341",
        product_id="0036",
        name="Arduino Leonardo (ATmega32U4)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Arduino Leonardo",
        target_chip="ATmega32U4",
        recommended_sdk="arduino-cli",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Arduino Leonardo native USB CDC/HID microcontroller"
    ),
    "2341:0042": HardwareEntry(
        vendor_id="2341",
        product_id="0042",
        name="Arduino Mega 2560 R3",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Arduino Mega 2560",
        target_chip="ATmega2560",
        recommended_sdk="arduino-cli",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Arduino Mega 2560 with onboard 16U2 USB-to-serial"
    ),
    "2341:0058": HardwareEntry(
        vendor_id="2341",
        product_id="0058",
        name="Arduino Nano Every (m4809)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Arduino Nano Every",
        target_chip="ATmega4809",
        recommended_sdk="arduino-cli",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Arduino Nano Every with SAMD11D14A USB bridge"
    ),
    "2341:1002": HardwareEntry(
        vendor_id="2341",
        product_id="1002",
        name="Arduino Nano RP2040 Connect",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Arduino Nano RP2040 Connect",
        target_chip="RP2040",
        recommended_sdk="arduino-cli",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Arduino RP2040 board with Wi-Fi and Bluetooth"
    ),

    # Teensy
    "16c0:0483": HardwareEntry(
        vendor_id="16c0",
        product_id="0483",
        name="PJRC Teensy USB Serial (Teensy 3.x / 4.x)",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="Teensy 4.0 / 4.1",
        target_chip="i.MX RT1062",
        recommended_sdk="teensy-core",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="PJRC Teensy high performance microcontroller"
    ),

    # Nordic Semiconductor
    "1915:521f": HardwareEntry(
        vendor_id="1915",
        product_id="521f",
        name="Nordic Semiconductor nRF52840 Dongle",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="nRF52840 Dongle (PCA10059)",
        target_chip="nRF52840",
        recommended_sdk="nrf-connect-sdk",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Nordic nRF52840 USB dongle for BLE / Thread / Zigbee"
    ),
    "1915:520f": HardwareEntry(
        vendor_id="1915",
        product_id="520f",
        name="Nordic Semiconductor nRF52840 Development Kit",
        classification=DeviceClassification.NATIVE_MCU,
        target_board="nRF52840 DK (PCA10056)",
        target_chip="nRF52840",
        recommended_sdk="nrf-connect-sdk",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Nordic nRF52840 DK with onboard J-Link interface"
    ),

    # =========================================================================
    # STAGE 1: HARDWARE DEBUGGERS & PROBES (Direct Descriptors -> Debugger Toolchain)
    # =========================================================================
    # ST-LINK
    "0483:3748": HardwareEntry(
        vendor_id="0483",
        product_id="3748",
        name="STMicroelectronics ST-LINK/V2 Debugger",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="STM32 Target Board (SWD/JTAG)",
        target_chip="STM32",
        recommended_sdk="stm32cube-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="ST-LINK/V2 in-circuit debugger and programmer for STM8 and STM32"
    ),
    "0483:374b": HardwareEntry(
        vendor_id="0483",
        product_id="374b",
        name="STMicroelectronics ST-LINK/V2-1 (Nucleo/Discovery)",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="STM32 Nucleo / Discovery Board",
        target_chip="STM32",
        recommended_sdk="stm32cube-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="ST-LINK/V2-1 with Virtual COM port and mass-storage programming"
    ),
    "0483:374e": HardwareEntry(
        vendor_id="0483",
        product_id="374e",
        name="STMicroelectronics ST-LINK/V3",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="STM32 Target Board (SWD/JTAG)",
        target_chip="STM32",
        recommended_sdk="stm32cube-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Next-generation ST-LINK/V3 modular in-circuit probe"
    ),

    # SEGGER J-Link
    "1366:0101": HardwareEntry(
        vendor_id="1366",
        product_id="0101",
        name="SEGGER J-Link ARM Debugger",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="ARM Cortex-M Target",
        target_chip="ARM",
        recommended_sdk="jlink-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="SEGGER J-Link standard JTAG/SWD probe"
    ),
    "1366:1015": HardwareEntry(
        vendor_id="1366",
        product_id="1015",
        name="SEGGER J-Link EDU Mini",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="ARM / RISC-V Target",
        target_chip="ARM",
        recommended_sdk="jlink-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="SEGGER J-Link EDU Mini educational debugger"
    ),
    "1366:0105": HardwareEntry(
        vendor_id="1366",
        product_id="0105",
        name="SEGGER J-Link On-Board (OB)",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="Integrated DevKit Target",
        target_chip="ARM",
        recommended_sdk="jlink-tools",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="On-board SEGGER J-Link debugger embedded on third-party kits"
    ),

    # CMSIS-DAP / DAPLink
    "0d28:0204": HardwareEntry(
        vendor_id="0d28",
        product_id="0204",
        name="ARM DAPLink / CMSIS-DAP Debugger (BBC micro:bit)",
        classification=DeviceClassification.DEBUG_PROBE,
        target_board="BBC micro:bit / CMSIS-DAP Target",
        target_chip="nRF52833",
        recommended_sdk="pyocd",
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="ARM DAPLink interface firmware providing SWD and CDC serial"
    ),

    # =========================================================================
    # STAGE 2: GENERIC USB-TO-UART BRIDGES (Ambiguous Bridge -> Needs Manifest)
    # =========================================================================
    # Silicon Labs CP210x
    "10c4:ea60": HardwareEntry(
        vendor_id="10c4",
        product_id="ea60",
        name="Silicon Labs CP2102/CP2104 USB-to-UART Bridge",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,  # AMBIGUOUS: Could be ESP32, ESP8266, STM32, Arduino, or UART Sensor
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Generic UART bridge chip. Target board must be resolved via .hades.yaml manifest."
    ),
    "10c4:ea70": HardwareEntry(
        vendor_id="10c4",
        product_id="ea70",
        name="Silicon Labs CP2105 Dual USB-to-UART Bridge",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Dual channel generic UART bridge chip."
    ),

    # WCH CH340 / CH341
    "1a86:7523": HardwareEntry(
        vendor_id="1a86",
        product_id="7523",
        name="WCH CH340 / CH340G USB-to-Serial Converter",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,  # AMBIGUOUS: Common on cheap ESP32 DevKitC clones & Arduino Nano clones
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Generic WCH serial converter widely used on development board clones."
    ),
    "1a86:5523": HardwareEntry(
        vendor_id="1a86",
        product_id="5523",
        name="WCH CH341 USB-to-UART / Parallel Converter",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="WCH multi-protocol bridge chip."
    ),
    "1a86:55d4": HardwareEntry(
        vendor_id="1a86",
        product_id="55d4",
        name="WCH CH9102F High-Speed USB-to-Serial",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Modern WCH serial bridge popular on newer ESP32 modules."
    ),

    # FTDI
    "0403:6001": HardwareEntry(
        vendor_id="0403",
        product_id="6001",
        name="FTDI FT232R USB-to-UART Bridge",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,  # AMBIGUOUS: Arduino Nano classic, FTDI cable, custom board
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="FTDI standard UART bridge. Ambiguous target board."
    ),
    "0403:6010": HardwareEntry(
        vendor_id="0403",
        product_id="6010",
        name="FTDI FT2232C/D/H Dual USB-UART/JTAG",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Dual channel FTDI bridge used for JTAG and serial console."
    ),
    "0403:6014": HardwareEntry(
        vendor_id="0403",
        product_id="6014",
        name="FTDI FT232H Hi-Speed Single Channel",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="FTDI high-speed USB interface."
    ),

    # Prolific
    "067b:2303": HardwareEntry(
        vendor_id="067b",
        product_id="2303",
        name="Prolific PL2303 USB-to-Serial Port",
        classification=DeviceClassification.GENERIC_UART_BRIDGE,
        target_board=None,
        target_chip=None,
        recommended_sdk=None,
        isolation=IsolationRecommendation.CONTAINER_BROKER,
        description="Generic Prolific serial adapter."
    ),

    # =========================================================================
    # SYSTEM HOST HUBS & CONTROLLERS (Filtered by default unless --all is set)
    # =========================================================================
    "1d6b:0001": HardwareEntry(
        vendor_id="1d6b",
        product_id="0001",
        name="Linux Foundation 1.1 Root Hub",
        classification=DeviceClassification.HOST_HUB,
        isolation=IsolationRecommendation.REJECT_POLICY,
        description="Host controller root hub"
    ),
    "1d6b:0002": HardwareEntry(
        vendor_id="1d6b",
        product_id="0002",
        name="Linux Foundation 2.0 Root Hub",
        classification=DeviceClassification.HOST_HUB,
        isolation=IsolationRecommendation.REJECT_POLICY,
        description="Host controller root hub"
    ),
    "1d6b:0003": HardwareEntry(
        vendor_id="1d6b",
        product_id="0003",
        name="Linux Foundation 3.0 Root Hub",
        classification=DeviceClassification.HOST_HUB,
        isolation=IsolationRecommendation.REJECT_POLICY,
        description="Host controller root hub"
    ),
}


def lookup_hardware(vendor_id: str, product_id: str) -> Optional[HardwareEntry]:
    """Look up a device by VID:PID (case-insensitive hex)."""
    vid_pid = f"{vendor_id.lower()}:{product_id.lower()}"
    return HARDWARE_DATABASE.get(vid_pid)

