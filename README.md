# DNP Direct Print for iPad

Experimental iPadOS app and USBDriverKit extension for printing directly from
an M-series iPad to DNP DS-RX1HS and QW410 printers without a WCM/WCM Plus
module.

The default workflow is 4×6 on both printers. RX1HS 6×8 and QW410 4.5×8 are
also scaffolded. The app picks a photo, crops it to the printer's native 300
dpi raster, generates the DNP three-plane job, checks printer status/free
buffers, and streams one test copy over USB.

## What is included

- SwiftUI iPad photo picker and one-copy test UI
- RX1HS USB match `1343:0005`
- QW410 USB match `1452:9201`
- USBDriverKit bulk OUT/IN transport with bounded user-client calls
- DNP status and free-buffer queries
- RX1HS 4×6 and 6×8 raster/job generation
- QW410 4×6 and 4.5×8 raster/job generation
- protocol/job unit tests and a macOS GitHub Actions workflow

## Current status

This is source-complete for the first hardware experiment. GitHub Actions
generates the project, compiles the unsigned iPad app and DriverKit extension
with Xcode 16.4, and runs the protocol/job tests. It has not yet been signed,
installed, or tested on a physical iPad/printer. It cannot run until your Apple
Developer team receives the required DriverKit USB entitlements. The code uses
a public, independently reimplemented DNP command path; it does not include
DNP's official color profiles, so first-print color is experimental.

Read these before testing:

- [Physical connection](docs/HARDWARE.md)
- [Apple entitlement and signing setup](docs/APPLE_ENTITLEMENTS.md)
- [How to apply for Apple DriverKit entitlements](docs/DRIVERKIT_APPLICATION_GUIDE.md)
- [First hardware test plan](docs/TEST_PLAN.md)
- [Protocol details and sources](docs/PROTOCOL_NOTES.md)

## Generate and open the project

On a Mac, replace `com.example.dnpdirectprint` with your own bundle prefix,
then run:

```bash
brew install xcodegen
./scripts/bootstrap.sh
open DNPDirectPrint.xcodeproj
```

Use a physical M-series iPad running iPadOS 16 or later. Set your approved
provisioning profiles on the app and driver targets, run the app, enable the
driver in iPad Settings, attach the printer, and tap **Probe printer** before
sending one copy.

## Hardware in one line

For event use: `iPad USB-C → powered USB-C PD hub → USB-A-to-B cable → DNP
printer`, while the iPad remains on the Wi-Fi router. The router does not carry
the print job.

## Development priorities after first print

The next milestone is driven by hardware logs and the printed sample: confirm
endpoint selection and orientation, add official/licensed color calibration,
validate loaded media before sending, handle two-buffer matte transitions,
add cancellation/recovery, and soak-test repeated event printing.

Licensed under MIT. See [NOTICE.md](NOTICE.md) for attribution and trademark
notices.
