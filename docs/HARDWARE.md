# Physical setup

## Recommended event setup

```text
Wi-Fi router ))) iPad Pro/Air with M-series chip
                       |
                       | USB-C
                powered USB-C hub
                 |             |
              USB-A          USB-C PD charger
                 |
          USB-A to USB-B cable
                 |
       RX1HS or QW410 USB-B printer port

Printer AC cable ---------------- wall power
```

The router is not part of the print path. Keep the iPad joined to the router's
Wi-Fi for the photo booth, internet, or local event traffic while the printer
uses USB.

For a short bench test, connect an M-series iPad directly with a USB-C to
USB-B data cable. For an event, use a reputable powered USB-C hub or dock with
USB Power Delivery so the iPad can charge while acting as the USB host. The
printer is self-powered and must use its own AC cable (or the supported QW410
power option).

Use the printer's square USB-B data port. Do not connect to a USB accessory
port, a router USB port, or the printer through the router. DNP's manuals call
for a shielded USB 2.0-compatible cable. Keep the cable short and avoid
unpowered hubs.

## Connection order for the first test

1. Load the correct 4×6 media and ribbon, close the printer, and turn it on.
2. Power the USB-C hub and connect the iPad charger to the hub's PD input.
3. Connect the hub to the iPad.
4. Connect USB-A on the hub to USB-B on the printer.
5. Open iPad Settings, search for `Drivers`, and enable DNP Direct Print.
6. Return to the app and tap **Probe printer**. Expect `Idle` and at least one
   free print buffer.
7. Choose a photo and send one test copy.

If the driver does not appear, disconnect the printer, restart the iPad after
installing the app, enable the driver, and reconnect the USB cable.

