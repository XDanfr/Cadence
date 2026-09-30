import XCTest
@testable import CadenceCore

@MainActor private final class FakeNotifications: NotificationClient {
    var access = NotificationAccess(permission: .notDetermined)
    var requests = 0
    var adds: [IntervalNotification] = []
    var pending: IntervalNotification?
    var requestError: Error?
    var addError: Error?
    var addStarted: (() -> Void)?
    var finishAdd: CheckedContinuation<Void, Never>?
    var delayAdd = false
    func settings() async -> NotificationAccess { access }
    func requestPermission() async throws {
        requests += 1
        if let requestError { throw requestError }
        access.permission = .authorised
    }
    func add(_ notification: IntervalNotification) async throws {
        adds.append(notification)
        if delayAdd {
            await withCheckedContinuation { finishAdd = $0; addStarted?() }
        }
        if let addError { throw addError }
        pending = notification
    }
    func removeInterval() { pending = nil }
    func removeAllCadenceNotifications() { pending = nil }
}

@MainActor final class NotificationTests: XCTestCase {
    private func reminder(_ title: String = "Focus ended") -> IntervalNotification {
        IntervalNotification(deadline: Date().addingTimeInterval(60), title: title, body: "Break time")
    }
    func testUndecidedAccessNeverSchedulesOrPromptsWithoutAnExplicitRequest() async {
        let client = FakeNotifications(); let coordinator = NotificationCoordinator(client: client)
        await coordinator.replace(with: reminder()).value
        XCTAssertEqual(client.requests, 0); XCTAssertTrue(client.adds.isEmpty)
        await coordinator.requestPermission()
        XCTAssertEqual(client.requests, 1); XCTAssertEqual(coordinator.access.permission, .authorised)
        await coordinator.replace(with: reminder()).value
        XCTAssertNotNil(client.pending)
    }
    func testDeniedAccessIsNotRequestedRepeatedly() async {
        let client = FakeNotifications(); client.access.permission = .denied
        let coordinator = NotificationCoordinator(client: client)
        await coordinator.requestPermission()
        await coordinator.replace(with: reminder()).value
        XCTAssertEqual(client.requests, 0); XCTAssertNil(client.pending)
        XCTAssertEqual(coordinator.access.permission, .denied)
    }
    func testRefreshReflectsPermissionChangesFromSystemSettings() async {
        let client = FakeNotifications(); client.access.permission = .denied
        let coordinator = NotificationCoordinator(client: client)
        await coordinator.refresh(); XCTAssertEqual(coordinator.access.permission, .denied)
        client.access = NotificationAccess(permission: .authorised, alertsEnabled: false)
        await coordinator.refresh()
        XCTAssertTrue(coordinator.access.permission.canSchedule); XCTAssertFalse(coordinator.access.alertsEnabled)
        client.access.permission = .denied
        await coordinator.replace(with: reminder()).value
        XCTAssertNil(client.pending)
    }
    func testRegistrationFailureDoesNotPretendUserDeniedPermission() async {
        let client = FakeNotifications()
        client.requestError = NSError(domain: "UNErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notifications are not allowed for this application"])
        let coordinator = NotificationCoordinator(client: client)
        await coordinator.requestPermission()
        XCTAssertEqual(coordinator.access.permission, .notDetermined)
        XCTAssertNotNil(coordinator.issue); XCTAssertFalse(coordinator.requesting)
    }
    func testSchedulingFailureIsReported() async {
        let client = FakeNotifications(); client.access.permission = .authorised
        client.addError = NSError(domain: "Test", code: 1)
        let coordinator = NotificationCoordinator(client: client)
        await coordinator.replace(with: reminder()).value
        XCTAssertNotNil(coordinator.issue)
    }
    func testPauseWhileAddingCannotResurrectPendingReminder() async {
        let client = FakeNotifications(); client.access.permission = .authorised; client.delayAdd = true
        let coordinator = NotificationCoordinator(client: client)
        let started = expectation(description: "add began")
        client.addStarted = { started.fulfill() }
        let old = coordinator.replace(with: reminder())
        await fulfillment(of: [started], timeout: 2)
        let paused = coordinator.replace(with: nil)
        client.finishAdd?.resume(); client.finishAdd = nil
        await old.value; await paused.value
        XCTAssertNil(client.pending)
    }
    func testNewDeadlineWinsAfterInFlightOldRequest() async {
        let client = FakeNotifications(); client.access.permission = .authorised; client.delayAdd = true
        let coordinator = NotificationCoordinator(client: client)
        let started = expectation(description: "first add began")
        client.addStarted = { started.fulfill() }
        let old = coordinator.replace(with: reminder("Old"))
        await fulfillment(of: [started], timeout: 2)
        let latest = reminder("New")
        let replacement = coordinator.replace(with: latest)
        client.delayAdd = false; client.finishAdd?.resume(); client.finishAdd = nil
        await old.value; await replacement.value
        XCTAssertEqual(client.pending, latest)
    }
}
