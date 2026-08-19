# Applying for Apple DriverKit entitlements

This guide covers the entitlement request for embedding the DNP USB driver in
an existing iPadOS photobooth app distributed through TestFlight. DriverKit is
a managed capability: adding keys to an entitlements file is not enough. Apple
must authorize the capabilities in the provisioning profiles used to sign the
host app and its embedded driver extension.

## Required identifiers

Create or retain two explicit App IDs under the same Apple Developer team:

| Component | Example bundle identifier |
| --- | --- |
| Existing photobooth app | `com.yourcompany.photobooth` |
| Embedded DriverKit extension | `com.yourcompany.photobooth.dnp-usb-driver` |

Replace the examples with permanent identifiers owned by your organization.
Do not use a wildcard App ID for either component.

## Required capabilities

The photobooth app needs:

- System Extension
- DriverKit Communicates with Drivers

The resulting app entitlement includes:

```xml
<key>com.apple.developer.driverkit.communicates-with-drivers</key>
<true/>
<key>com.apple.developer.system-extension.install</key>
<true/>
```

The embedded driver needs a DriverKit entitlement group containing:

```text
com.apple.developer.driverkit
com.apple.developer.driverkit.transport.usb
```

Request access only to the supported DNP devices:

| Printer | USB vendor ID | USB product ID |
| --- | ---: | ---: |
| DNP DS-RX1HS | `0x1343` / `4931` | `0x0005` / `5` |
| DNP QW410 | `0x1452` / `5202` | `0x9201` / `37377` |

The application does not need DriverKit Allow Third Party User Clients when
only the embedding photobooth app communicates with the driver.

## Before submitting

Prepare the following information:

- Apple Developer Team ID and Account Holder contact
- Host app and driver extension bundle identifiers
- A short description of the photobooth workflow
- Printer names and exact USB vendor/product identifiers
- An explanation of the USB operations the driver performs
- Planned distribution method, currently internal TestFlight
- Any written authorization or technical cooperation available from DNP

The USB vendor IDs belong to DNP, so Apple may ask about your relationship with
the hardware manufacturer. Include a DNP authorization letter or email if one
is available.

## Submit the request

The request must be submitted by the Apple Developer organization’s Account
Holder.

1. Sign in to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. Open **Identifiers** and select the explicit App ID for the driver
   extension.
3. Open the **Capability Requests** tab.
4. Request DriverKit and DriverKit USB Transport.
5. Enter both DNP USB vendor/product pairs and submit the form.
6. Select the host photobooth App ID and request or enable DriverKit
   Communicates with Drivers. Enable the System Extension capability as well.

If the DriverKit request is not offered in the Capability Requests tab, use
Apple’s signed-in [System Extension entitlement request](https://developer.apple.com/contact/request/system-extension/)
and identify both bundle IDs in the submission.

Apple requires all DriverKit entitlements used for one product to be included
in the same approved entitlement group. Request DriverKit and USB Transport
together rather than as unrelated product requests.

## Suggested request description

The following text can be adapted for the request form:

```text
We are developing an iPadOS photobooth application that prints completed
event photographs directly to DNP DS-RX1HS and DNP QW410 dye-sublimation
photo printers over USB.

The DriverKit extension is embedded in our application and supports only USB
vendor/product IDs 1343:0005 and 1452:9201. It performs printer-status and
available-buffer queries and transfers rasterized photo print jobs. It does
not update printer firmware, access unrelated USB devices, or accept
connections from third-party applications.

The application is currently distributed to our team through internal
TestFlight for development and hardware testing. A user explicitly enables
the driver in iPad Settings before connecting a supported printer.

This integration replaces the need for an external DNP wireless print-server
module in controlled photobooth installations.
```

If the form asks why standard APIs are insufficient, explain that RX1HS and
QW410 expose USB interfaces requiring model-specific bidirectional status
queries and bulk print-job transfers. They are not network or AirPrint
printers.

## Monitor the request

Check the request at:

```text
Certificates, Identifiers & Profiles
→ Identifiers
→ Select the App ID
→ Capability Requests
→ Status
```

Apple does not publish an approval time. Respond to requests for hardware,
security, company, or DNP authorization information using the same support
case.

## Configure signing after approval

After Apple assigns the managed capabilities:

1. Open each App ID in Certificates, Identifiers & Profiles.
2. Enable the approved capabilities under **Capabilities** and save.
3. In Xcode, add System Extension and Communicates with Drivers to the host
   app target.
4. Add DriverKit and USB Transport to the driver extension target.
5. Keep the USB entitlement restricted to the two approved vendor/product
   pairs.
6. Refresh signing assets in Xcode or recreate the affected provisioning
   profiles.

For direct device testing, create a
[DriverKit development provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-a-driverkit-development-provisioning-profile)
for the driver App ID and register the test iPad. For TestFlight, archive using
App Store Connect distribution signing. Xcode Automatic Signing can choose the
appropriate profile type after the capabilities have been enabled.

## Verify before TestFlight upload

Before uploading an archive:

- Confirm the driver extension is embedded in the host app.
- Confirm the archive is signed by the intended Apple Developer team.
- Inspect the signed host app and driver entitlements in Xcode Organizer.
- Confirm the distribution provisioning profiles contain the managed
  DriverKit capabilities, not only the local `.entitlements` files.
- Install a direct development build on an M-series iPad and verify that the
  driver appears in the app’s iPad Settings page.
- Enable the driver, reconnect one attended printer, run **Probe printer**, and
  send a single 4×6 test job before creating a TestFlight build.

A TestFlight build can upload successfully yet fail at driver activation or
`IOServiceOpen` if its distribution provisioning profile does not authorize
the requested entitlements.

## Apple references

- [Requesting Entitlements for DriverKit Development](https://developer.apple.com/documentation/driverkit/requesting-entitlements-for-driverkit-development)
- [Request access to managed capabilities](https://developer.apple.com/help/account/capabilities/capability-requests)
- [Creating drivers for iPadOS](https://developer.apple.com/documentation/driverkit/creating-drivers-for-ipados)
- [Create a DriverKit development provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-a-driverkit-development-provisioning-profile)
- [System Extensions and DriverKit](https://developer.apple.com/system-extensions/)
