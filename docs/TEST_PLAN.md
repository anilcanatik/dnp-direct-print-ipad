# First hardware test plan

## Safety boundary

This is a protocol prototype, not a production printer driver. Keep the
printer attended, load only the correct media, and send one copy. A malformed
job should be rejected as a data error, but do not use the prototype for an
unattended paid event until status recovery, cancellation, media validation,
and repeated-print soak testing are complete.

## Bench checks

1. Build and run `DNPPrintCoreTests` in an iPad simulator. These tests validate
   32-byte command framing, RX1HS/QW410 multicut values, plane sizes, and the
   final START command.
2. Install the signed app and enable its driver in iPad Settings.
3. With no printer attached, confirm **Probe printer** reports that the driver
   is unavailable.
4. Attach RX1HS with 4×6 media. Probe must report `Idle` and one or more free
   buffers. Print a neutral gray test image, then a color chart, then a normal
   photograph.
5. Repeat with QW410 and 4×6 media. Confirm the 71-dot white imaging margins
   are not visible after the printer's normal borderless overcut.
6. Test glossy and matte separately. Do not rapidly alternate finishes until
   two-buffer handling is added.
7. Test error reporting by opening and closing the cover before a probe; do
   not intentionally interrupt a job in the first test.

## Acceptance criteria for milestone 1

- iPad discovers the correct model only when its USB cable is attached.
- Probe returns recognizable status and free-buffer values.
- One 4×6 print starts without a WCM/WCM Plus module.
- Output is correctly oriented, fills the sheet, and has sane RGB channel
  order.
- Disconnect/reconnect restores operation without reinstalling the app.

Photograph the resulting print and save the app/driver Console logs for the
next iteration. Color calibration, production retry logic, and long-event soak
tests are milestone 2.

