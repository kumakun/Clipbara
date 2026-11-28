import AppKit
import SwiftUI
import XCTest

final class WheelScrollTranslationTests: XCTestCase {
    private func input(
        dx: Double = 0,
        dy: Double = -1,
        phase: WheelScrollTranslation.Phase = .none,
        horizontal: Bool = true,
        vertical: Bool = false
    ) -> WheelScrollTranslation.Input {
        WheelScrollTranslation.Input(
            deltaX: dx,
            deltaY: dy,
            phase: phase,
            canScrollHorizontally: horizontal,
            canScrollVertically: vertical
        )
    }

    // MARK: - Which scrolls move a sideways row

    func testAWheelNotchMovesASidewaysRow() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dy: -1)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: 1)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -3)))
    }

    func testASidewaysScrollIsLeftAlone() {
        // Shift + wheel, a thumb wheel, and a sideways swipe all arrive as
        // horizontal movement and already work.
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: -1, dy: 0)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: -3, dy: 1)))
    }

    func testAHighResolutionVerticalScrollAlsoMovesTheRow() {
        // A mouse with vendor smooth scrolling reports the same fine deltas a
        // trackpad does, so the device kind cannot be the deciding factor.
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0.4, dy: -6.2, phase: .began)))
    }

    func testViewsThatAlsoScrollVerticallyKeepTheScroll() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dy: -1, vertical: true)))
    }

    func testViewsThatCannotScrollSidewaysAreIgnored() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dy: -1, horizontal: false)))
        XCTAssertFalse(translator.shouldTranslate(input(dy: -1, horizontal: false, vertical: true)))
    }

    func testAnEmptyScrollDoesNothing() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0)))
    }

    // MARK: - One decision per gesture

    func testAVerticalGestureCanBeginWithoutMovement() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .began)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .changed)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -6, phase: .changed)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -2, phase: .momentum)))
    }

    func testASidewaysGestureCanBeginWithoutMovement() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .began)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: -6, dy: 0, phase: .changed)))
        XCTAssertFalse(translator.shouldTranslate(input(dy: -6, phase: .changed)))
    }

    func testAnEmptyBeginningClearsThePreviousGestureDirection() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: -6, dy: 0, phase: .began)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .ended)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .began)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -6, phase: .changed)))
    }

    func testAWheelNotchClearsThePreviousGestureDirection() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: -6, dy: 0, phase: .began)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -1)))
        XCTAssertTrue(translator.shouldTranslate(input(dy: -6, phase: .changed)))
    }

    func testAWobblyVerticalSwipeDoesNotFlipMidGesture() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0.2, dy: -8, phase: .began)))
        // The swipe drifts sideways for a frame. It must not snap back to a
        // vertical scroll and jitter.
        XCTAssertTrue(translator.shouldTranslate(input(dx: -5, dy: -1, phase: .changed)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: -4, phase: .changed)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .ended)))
    }

    func testASidewaysSwipeStaysNativeForItsWholeRun() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertFalse(translator.shouldTranslate(input(dx: -9, dy: 0.3, phase: .began)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: -1, dy: 4, phase: .changed)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .ended)))
    }

    func testMomentumKeepsTheDecisionOfItsGesture() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: -9, phase: .began)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .ended)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: -3, dy: -2, phase: .momentum)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .momentumEnded)))
    }

    func testANewGestureDecidesAgain() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: -9, phase: .began)))
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: 0, phase: .momentumEnded)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: -9, dy: 0, phase: .began)))
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: -9, phase: .changed)))
    }

    func testLeavingASidewaysRowClearsTheDecision() {
        var translator = WheelScrollTranslation.Translator()
        XCTAssertTrue(translator.shouldTranslate(input(dx: 0, dy: -9, phase: .began)))
        // The pointer moves onto a view that scrolls both ways.
        XCTAssertFalse(translator.shouldTranslate(input(dx: 0, dy: -9, phase: .changed, vertical: true)))
        // Back on a sideways row, the stale decision must not be reused.
        XCTAssertFalse(translator.shouldTranslate(input(dx: -9, dy: 0, phase: .changed)))
    }

    // MARK: - Scroll events

    private func wheelEvent(lines: Int32) throws -> NSEvent {
        let cg = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: lines,
            wheel2: 0,
            wheel3: 0
        ))
        return try XCTUnwrap(NSEvent(cgEvent: cg))
    }

    @MainActor
    private func makeScrollView() -> NSScrollView {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        scroll.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 1500, height: 200))
        // The panel hides both scrollers. Scrolling must work without them.
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.horizontalLineScroll = 12
        return scroll
    }

    @MainActor
    func testDownAndUpWheelNotchesMoveTheListInBothDirections() throws {
        let scroll = makeScrollView()
        WheelScrollTranslation.scrollHorizontally(with: try wheelEvent(lines: -3), in: scroll)
        XCTAssertGreaterThan(scroll.contentView.bounds.minX, 0)
        XCTAssertEqual(scroll.contentView.bounds.minY, 0)
        WheelScrollTranslation.scrollHorizontally(with: try wheelEvent(lines: 3), in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.minX, 0, accuracy: 0.001)
    }

    @MainActor
    func testWheelNotchesUseTheScrollViewsLineDistance() throws {
        let scroll = makeScrollView()
        let event = try wheelEvent(lines: -3)
        WheelScrollTranslation.scrollHorizontally(with: event, in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.minX, -event.scrollingDeltaY * 12, accuracy: 0.001)
    }

    @MainActor
    func testSmoothScrollingUsesPointsForEachEvent() throws {
        let scroll = makeScrollView()
        let cg = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
            wheel1: -8, wheel2: 0, wheel3: 0
        ))
        let event = try XCTUnwrap(NSEvent(cgEvent: cg))
        XCTAssertTrue(event.hasPreciseScrollingDeltas)
        let distance = -event.scrollingDeltaY
        for step in 1...4 {
            WheelScrollTranslation.scrollHorizontally(with: event, in: scroll)
            XCTAssertEqual(scroll.contentView.bounds.minX, distance * CGFloat(step), accuracy: 0.001)
            XCTAssertEqual(scroll.contentView.bounds.minY, 0)
        }
    }

    @MainActor
    func testScrollingStopsAtBothEndsOfTheList() throws {
        let scroll = makeScrollView()
        WheelScrollTranslation.scrollHorizontally(with: try wheelEvent(lines: 1000), in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.minX, 0)
        WheelScrollTranslation.scrollHorizontally(with: try wheelEvent(lines: -1000), in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.maxX, 1500, accuracy: 0.001)
    }

    @MainActor
    func testSmoothGestureMovesASwiftUIRowAfterAnEmptyBeginning() throws {
        let host = NSHostingView(rootView: ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<12) { index in
                    Text("Card \(index)").frame(width: 200, height: 160)
                }
            }
        })
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.contentView = host
        host.layoutSubtreeIfNeeded()

        func findScrollView(in view: NSView) -> NSScrollView? {
            if let scroll = view as? NSScrollView { return scroll }
            return view.subviews.lazy.compactMap { findScrollView(in: $0) }.first
        }
        let scroll = try XCTUnwrap(findScrollView(in: host))
        let cg = try XCTUnwrap(CGEvent(
            scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
            wheel1: 0, wheel2: 0, wheel3: 0
        ))
        cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGScrollPhase.began.rawValue))
        let began = try XCTUnwrap(NSEvent(cgEvent: cg))
        // This zero-delta beginning reaches SwiftUI before a direction exists.
        scroll.scrollWheel(with: began)

        cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: Int64(CGScrollPhase.changed.rawValue))
        cg.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: -8)
        let changed = try XCTUnwrap(NSEvent(cgEvent: cg))
        XCTAssertTrue(changed.hasPreciseScrollingDeltas)
        XCTAssertEqual(changed.scrollingDeltaY, -8)
        WheelScrollTranslation.scrollHorizontally(with: changed, in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.minX, 8, accuracy: 0.001)

        cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: 0)
        cg.setIntegerValueField(.scrollWheelEventMomentumPhase, value: Int64(CGMomentumScrollPhase.begin.rawValue))
        let momentum = try XCTUnwrap(NSEvent(cgEvent: cg))
        WheelScrollTranslation.scrollHorizontally(with: momentum, in: scroll)
        XCTAssertEqual(scroll.contentView.bounds.minX, 16, accuracy: 0.001)
        XCTAssertEqual(scroll.contentView.bounds.minY, 0)
    }

    func testAWheelNotchReportsNoGesturePhase() throws {
        let wheel = try wheelEvent(lines: 1)
        XCTAssertEqual(WheelScrollTranslation.phase(of: wheel), .none)
    }
}
