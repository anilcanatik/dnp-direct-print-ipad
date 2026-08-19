# Protocol notes and sources

The app does not send JPEG data to the printer. It renders a fixed 300 dpi
RGBA image, emits DNP control commands, and converts the image into three
8-bit BMP-like planes. The DriverKit extension sends that stream through the
printer's bulk OUT endpoint and uses bulk IN for status/query responses.

Implemented presets:

| Model | USB ID | Print | Full raster | Multicut |
|---|---:|---:|---:|---:|
| DS-RX1HS | `1343:0005` | 4×6 | 1920×1240 | 2 |
| DS-RX1HS | `1343:0005` | 6×8 | 1920×2436 | 4 |
| QW410 | `1452:9201` | 4×6 | 1408×1836 | 48 |
| QW410 | `1452:9201` | 4.5×8 | 1408×2436 | 52 |

The RX1HS 4×6 raster includes 38 white dots at each side of its 1844-dot
image area. QW410 4×6 includes 71 white dots at each side of its 1266-dot
image area. These full-width rasters match the printer head width expected by
the DNP command stream.

Primary references:

- Apple, [Creating drivers for iPadOS](https://developer.apple.com/documentation/driverkit/creating-drivers-for-ipados)
- Apple, [USBDriverKit](https://developer.apple.com/documentation/usbdriverkit)
- Apple, [Requesting DriverKit entitlements](https://developer.apple.com/documentation/driverkit/requesting-entitlements-for-driverkit-development)
- DNP, [DS-RX1HS product information](https://www.dnpphoto.com/products/printers/rx1hs)
- DNP, [QW410 product information](https://www.dnpphoto.com/products/printers/qw410)
- Gutenprint, public source repository at
  [SourceForge](https://sourceforge.net/p/gimp-print/source/ci/master/tree/),
  especially `src/cups/backend_dnpds40.c` and
  `src/main/print-dyesub.c`

This implementation does not include DNP's proprietary color-control data or
an official DNP SDK. Initial prints may have color differences from DNP's Mac
or Windows driver. Do not redistribute profiles extracted from DNP software
without confirming their license.

