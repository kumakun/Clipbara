# Issue #26: mouse wheel over the sideways card rows

## Contract

- Scrolling vertically over the card row, a pinboard row, or the tab strip moves it sideways.
- A scroll that is already sideways is left alone, so Shift + wheel, a thumb wheel, and trackpad sideways gestures behave exactly as they do today.
- A view that also scrolls vertically, such as a Quick Look image at actual size, keeps the normal meaning of the scroll.
- The direction follows the system setting, using the movement reported by the device.
- No change to selection, paste, or the keyboard shortcuts.

The event's vertical movement is applied directly to the scroll view's horizontal offset. Precise events use point distances; ordinary wheel notches use the scroll view's horizontal line distance. AppKit constrains the offset to the document bounds. Copying the event and calling `HostingScrollView.scrollWheel(with:)` was observed to leave the offset at zero for real smooth-scroll input, even when the copied horizontal delta was correct.

The choice is made from the direction of the scroll, not from the kind of device. A mouse reports the same fine deltas a trackpad does once its vendor software turns on smooth scrolling, so treating precise deltas as "this is a trackpad, leave it alone" would skip exactly the mice this is meant to fix. Within one continuous gesture the first decision is kept until the gesture and its momentum finish, so a swipe that drifts off axis cannot flip between sideways and vertical frame by frame.

## Automated checks

```sh
bash scripts/test-and-launch.sh
```

Covered by unit tests:

- which scrolls get translated: a wheel notch, a high resolution vertical scroll, an already sideways scroll, both-axis views, and rows that do not scroll sideways
- one decision per gesture: a wobbly vertical swipe does not flip, a sideways swipe stays native for its whole run, momentum inherits the decision, a new gesture decides again, and leaving the row clears it
- zero-movement gesture beginnings wait for the first movement before choosing an axis; a new gesture or wheel notch clears the previous decision
- actual scroll offsets: down/up wheel notches move in opposite directions, line distance and precise point distances are respected, the vertical offset stays unchanged, and both ends clamp to the document
- a real SwiftUI horizontal scroll view moves after a zero-delta gesture beginning and continues during a synthetic momentum event

Not covered by unit tests: delivery of a real device event, the scroll view lookup under the pointer, and how the scrolling feels.

## Manual verification

1. Open the panel with enough clips to overflow the row. Scroll the wheel over the cards. The row moves sideways, and the direction matches the rest of the system.
2. Scroll over a pinboard row and over the tab strip when it overflows. Both move sideways.
3. Hold Shift and scroll. It still moves sideways, at the same speed as before this change.
4. Open Quick Look on an image and switch to actual size. The scroll still moves the image up and down.
5. On a trackpad, confirm sideways gestures are unchanged, and that a vertical swipe followed by momentum moves the row smoothly in one direction rather than jittering.
6. If the mouse has vendor software with smooth scrolling, check it with that setting both on and off.
7. Confirm clicking a card still pastes as before, and that scrolling over other windows is unaffected while the panel is open.

## Verification status

- 2026-11-28: real-device diagnostics reproduced the failure: the card row received smooth vertical input and correctly converted horizontal deltas, but its offset remained at zero. Replaced copied-event delivery with direct horizontal scrolling.
- 2026-11-28: all 119 unhosted unit tests passed, including actual offset checks and a SwiftUI gesture/momentum regression. The macOS Debug app built successfully. The local build was launched with sandboxing disabled to match the installed app's existing data directory.
- 2026-11-28: the user confirmed that up/down mouse-wheel scrolling now moves the actual card row sideways. Temporary diagnostics also recorded changing horizontal offsets in that row.
- 2026-09-11: `scripts/test-and-launch.sh` passed end to end. 26 unit tests, 0 failures, Debug build succeeded.
- 2026-09-11: scrolling the card row with an MX Master 3S was checked by hand and moved the row sideways.
- Not yet covered: the tab strip and pinboard rows, Quick Look at actual size, trackpad momentum, and the vendor smooth scrolling setting in both positions.
