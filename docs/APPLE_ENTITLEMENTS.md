# Apple signing and DriverKit entitlement setup

This project cannot claim the printer on an iPad until Apple approves the
DriverKit entitlements for your Developer Program team. Request the following
as one entitlement group:

- `com.apple.developer.driverkit`
- `com.apple.developer.driverkit.transport.usb` for RX1HS vendor/product
  `0x1343/0x0005` and QW410 `0x1452/0x9201`
- the host app's **Communicates with Drivers** capability
- the host app's **System Extension** capability

Use Apple's DriverKit entitlement request form linked from
<https://developer.apple.com/documentation/driverkit/requesting-entitlements-for-driverkit-development>.
Explain that the app is a directly attached, attended photo-printing client
for the DNP DS-RX1HS and QW410 and that it replaces an external network print
server. Apple may ask for proof that you are authorized to support USB vendor
IDs owned by DNP; obtain DNP or distributor cooperation if requested.

Before generating the project, replace all occurrences of
`com.example.dnpdirectprint` in `project.yml` and `Driver/Info.plist` with a
reverse-DNS identifier owned by your team. The driver bundle identifier must
remain prefixed by the app identifier, for example:

```text
App:    com.yourcompany.dnpdirectprint
Driver: com.yourcompany.dnpdirectprint.driver
```

Create explicit App IDs and provisioning profiles for the iPad app and the
DriverKit extension. The driver profile type is **DriverKit App Development**.
Assign the approved entitlement group to the driver App ID and the
Communicates with Drivers/System Extension capabilities to the host App ID.

On a Mac with current Xcode and XcodeGen:

```bash
brew install xcodegen
./scripts/bootstrap.sh
open DNPDirectPrint.xcodeproj
```

Select your development team for both targets, choose the matching profiles,
connect the M-series iPad, and run the `DNPDirectPrint` scheme on the physical
iPad. DriverKit does not run this USB path in the iPad Simulator.

