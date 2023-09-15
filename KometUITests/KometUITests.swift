//
//  KometUITests.swift
//  KometUITests
//
//  Created by Mayur Pawashe on 10/4/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import XCTest

private let OVERFLOW_SUBJECT_THRESHOLD = 69
private let OVERFLOW_BODY_THRESHOLD = 72

private let KOMET_ERROR_DOMAIN = "KometErrorDomain"
private let KOMET_COMMIT_ERROR = 1

class KometApp {
	let initialContent: String
	private let textView: XCUIElement
	
	private let application: XCUIApplication
	private let fileURL: URL
	private let tempDirectoryURL: URL
	private let breadcrumbsURL: URL
	
	init(filename: String, automicNewlineInsertion: Bool = true, resumeIncompleteSession: Bool = false, versionControlledFile: Bool = true) throws {
		let bundle = Bundle(for: Self.self)
		let resourceURL = bundle.url(forResource: filename, withExtension: "")!
		
		let fileManager = FileManager.default
		
		let uuid = UUID().uuidString
		tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("komet_" + uuid)
		
		let projectDirectoryURL = tempDirectoryURL.appendingPathComponent("Project")
		try fileManager.createDirectory(at: projectDirectoryURL, withIntermediateDirectories: true, attributes: nil)
		
		fileURL = tempDirectoryURL.appendingPathComponent(resourceURL.lastPathComponent)
		try fileManager.copyItem(at: resourceURL, to: fileURL)
		
		initialContent = try String(contentsOf: fileURL)
		
		let key = { (defaultName: String) in
			return "-\(defaultName)"
		}
		
		breadcrumbsURL = projectDirectoryURL.appendingPathComponent("komet_breadcrumbs.json")
		
		application = XCUIApplication()
		application.launchArguments =
			[fileURL.path,
			 key(ZGEditorAutomaticNewlineInsertionAfterSubjectKey), String(automicNewlineInsertion),
			 key(ZGResumeIncompleteSessionKey), String(resumeIncompleteSession),
			 key(ZGResumeIncompleteSessionTimeoutIntervalKey), String(60.0 * 5),
			 key(ZGDisableSpellCheckingAndCorrectionForSquashesKey), String(true),
			 key(ZGDetectHGCommentStyleForSquashesKey), String(true),
			 key(ZGDisableSpellCheckingAndCorrectionForSquashesKey), String(true),
			 key(ZGEditorRecommendedSubjectLengthLimitEnabledKey), String(true),
			 key(ZGEditorRecommendedSubjectLengthLimitKey), String(OVERFLOW_SUBJECT_THRESHOLD),
			 key(ZGEditorRecommendedBodyLineLengthLimitEnabledKey), String(true),
			 key(ZGEditorRecommendedBodyLineLengthLimitKey), String(OVERFLOW_BODY_THRESHOLD),
			 key(ZGWindowStyleThemeKey), String(WindowStyleTheme.plain.rawValue),
			 key(ZGWindowVibrancyKey), String(false),
			 key(ZGMessageFontNameKey), "",
			 key(ZGMessageFontPointSizeKey), String(0.0),
			 key(ZGCommentsFontNameKey), "",
			 key(ZGCommentsFontPointSizeKey), String(0.0),
			 key(ZGAssumeVersionControlledFileKey), String(versionControlledFile),
			 key(ZGCommitTextViewContinuousSpellCheckingKey), String(true),
			 key(ZGCommitTextViewAutomaticSpellingCorrectionKey), String(false),
			 key(ZGCommitTextViewAutomaticTextReplacementKey), String(false)]
		
		application.launchEnvironment = [
			ZGBreadcrumbsURLKey: breadcrumbsURL.path,
			ZGProjectNameKey: tempDirectoryURL.lastPathComponent
		]
		application.launch()
		
		textView = application.windows.textViews.element
	}
	
	func removeTemporaryDirectory() {
		let _ = try? FileManager.default.removeItem(at: tempDirectoryURL)
	}
	
	deinit {
		removeTemporaryDirectory()
	}
	
	private func waitForExit() throws -> (Breadcrumbs?, String) {
		// Wait for a while until the breadcrumbs file becomes available
		var breadcrumbsDataCandidate: Data? = nil
		var breadcrumbCandidateAttempts = 20
		while breadcrumbsDataCandidate == nil && breadcrumbCandidateAttempts > 0 {
			sleep(1)
			breadcrumbsDataCandidate = try? Data(contentsOf: breadcrumbsURL)
			breadcrumbCandidateAttempts -= 1
		}
		
		let breadcrumbsData: Data
		if let breadcrumbsDataCandidate = breadcrumbsDataCandidate {
			breadcrumbsData = breadcrumbsDataCandidate
		} else {
			// Try retrieving breadcrumbs one last time
			breadcrumbsData = try Data(contentsOf: breadcrumbsURL)
		}
		
		let breadcrumbs = try JSONDecoder().decode(Breadcrumbs.self, from: breadcrumbsData)
		
		let finalContent = try String(contentsOf: fileURL)
		return (breadcrumbs, finalContent)
	}
	
	func commit() throws -> (Breadcrumbs?, String) {
		application.menuBars.menuBarItems["File"].menuItems["Commit"].click()
		
		// For some reason we need to send activate message before querying the application's sheets
		// Otherwise it may fail to retrieve a snapshot
		application.activate()
		if application.sheets.count > 0 {
			// The error we supply doesn't really matter
			throw NSError(domain: KOMET_ERROR_DOMAIN, code: KOMET_COMMIT_ERROR, userInfo: nil)
		} else {
			return try waitForExit()
		}
	}
	
	func cancel() throws -> (Breadcrumbs?, String) {
		application.menuBars.menuBarItems["File"].menuItems["Cancel"].click()
		return try waitForExit()
	}
	
	func relaunch() {
		application.launch()
	}
	
	func typeText(_ text: String) {
		// Make sure we type newline characters separately to avoid them being typed too fast
		var currentText = text
		while let newlineIndex = currentText.firstIndex(of: "\n") {
			let line = currentText[currentText.startIndex ..< newlineIndex]
			if line.count > 0 {
				typeRawText(String(line))
			}
			typeRawText("\n")
			currentText = String(currentText[currentText.index(newlineIndex, offsetBy: 1) ..< currentText.endIndex])
		}
		
		if currentText.count > 0 {
			typeRawText(currentText)
		}
	}
	
	func typeRawText(_ text: String) {
		textView.typeText(text)
	}
	
	func deleteText(count: Int) {
		for _ in 0 ..< count {
			textView.typeKey(.delete, modifierFlags: [])
		}
	}
	
	func selectAll() {
		application.menuBars.menuBarItems["Edit"].menuItems["Select All"].click()
	}
	
	private func moveCursor(key: XCUIKeyboardKey, count: Int) {
		for _ in 0 ..< count {
			textView.typeKey(key, modifierFlags: .function)
		}
	}
	
	func moveCursorDown(count: Int) {
		moveCursor(key: .downArrow, count: count)
	}
	
	func moveCursorRight(count: Int) {
		moveCursor(key: .rightArrow, count: count)
	}
	
	func moveCursorUp(count: Int) {
		moveCursor(key: .upArrow, count: count)
	}
	
	func moveCursorLeft(count: Int) {
		moveCursor(key: .leftArrow, count: count)
	}
}

class KometUITests: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.

		// In UI tests it is usually best to stop immediately when a failure occurs.
		continueAfterFailure = false

		// In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	// MARK: Simple
	
	func testNewCommit() throws {
		let app = try KometApp(filename: "new-commit")
	
		let newContent = "Hello there"
		app.typeText(newContent)
	
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + app.initialContent)
	}
	
	func testCanceledNewCommit() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.cancel()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit canceled empty message with non-zero exit status")
		XCTAssertEqual(finalContent, app.initialContent)
	}

	func testCanceledAmendedCommit() throws {
		let app = try KometApp(filename: "amended-commit")

		let newContent = "\nHello there"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.cancel()
		XCTAssertNotEqual(breadcrumbs!.exitStatus, 0, "commit canceled amended message with zero exit status")
		XCTAssertEqual(finalContent, app.initialContent)
	}

	func testNewCommitWithBody() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello there"
		let body = "That is okay."
		let newContent = subject + "\n" + body
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, "\(subject)\n\n\(body)\(app.initialContent)")
	}
	
	func testNewCommitWithError() throws {
		let app = try KometApp(filename: "new-commit")
		
		let newContent = "Hello there"
		app.typeText(newContent)
		
		app.removeTemporaryDirectory()
		
		do {
			let _ = try app.commit()
			XCTFail("Commit passed but should have failed")
		} catch {
			let kometError = error as NSError
			XCTAssertEqual(kometError.domain, KOMET_ERROR_DOMAIN)
			XCTAssertEqual(kometError.code, KOMET_COMMIT_ERROR)
		}
	}
	
	// MARK: Empty file
	
	func testEmptyCommitWithSubject() throws {
		let app = try KometApp(filename: "empty")
		
		let subject = "Hello there"
		app.typeText(subject)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, "\(subject)\n")
	}
	
	func testEmptyCommitWithEmptySubjectAndNewline() throws {
		let app = try KometApp(filename: "empty")
		app.typeText("\n")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, "\n\n")
	}
	
	func testEmptyCommitWithSubjectBodyAndNewline() throws {
		let app = try KometApp(filename: "empty")
		
		let subject = "Hello there"
		app.typeText(subject)
		app.typeText("\n")
		
		let body = "ok"
		app.typeText(body)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, "\(subject)\n\n\(body)\n")
	}
	
	// MARK: Selection

	func testSubjectSelection() throws {
		let app = try KometApp(filename: "new-commit")

		do {
			let newContent = "Hello there"
			app.typeText(newContent)
		}

		app.selectAll()

		let newContent = "Hi!"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + app.initialContent)
	}

	func testSubjectAndBodySelection() throws {
		let app = try KometApp(filename: "new-commit")

		do {
			let subject = "Hello there"
			let body = "That is okay."
			let newContent = subject + "\n" + body
			app.typeText(newContent)
		}

		app.selectAll()

		let newContent = "Hi!"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + app.initialContent)
	}

	func testSelectionWithTrailingNewline() throws {
		let app = try KometApp(filename: "new-commit")

		do {
			let subject = "Hello there"
			let body = "That is okay."
			let newContent = subject + "\n" + body
			app.typeText(newContent)
			app.typeText("\n")
		}

		app.selectAll()

		let newContent = "Hi!"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + "\n" + app.initialContent)
	}

	func testEmptySelection() throws {
		let app = try KometApp(filename: "new-commit")
		app.selectAll()

		let newContent = "Hi!"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + app.initialContent)
	}
	
	// MARK: Newline insertion

	func testNewCommitWithAutomaticNewlineInsertion() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there\n"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + "\n" + app.initialContent)
	}

	func testNewCommitWithoutAutomaticNewlineInsertion() throws {
		let app = try KometApp(filename: "new-commit", automicNewlineInsertion: false)

		let newContent = "Hello there\n"
		app.typeText(newContent)

		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + app.initialContent)
	}
	
	func testNewCommitWithNewlinePrevention() throws {
		let app = try KometApp(filename: "new-commit")
		
		let newContent = "Hello there"
		app.typeText(newContent)
		
		app.typeRawText("\n\n")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + "\n\n" + app.initialContent)
	}
	
	func testNewCommitWithNewlinePreventionAfterDelay() throws {
		let app = try KometApp(filename: "new-commit")
		
		let newContent = "Hello there"
		app.typeText(newContent)
		
		app.typeRawText("\n")
		sleep(2)
		app.typeRawText("\n")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0, "commit failed with non-zero status")
		XCTAssertEqual(finalContent, newContent + "\n\n\n" + app.initialContent)
	}
	
	// MARK: Text overflow
	
	func testNewCommitWithNoOverflowingSubjectLine() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello what"
		XCTAssertLessThan(newContent.count, OVERFLOW_SUBJECT_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testNewCommitWithAlmostOverflowingSubjectLine() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there what is going on now and what will happen when I overflow"
		XCTAssertEqual(newContent.count, OVERFLOW_SUBJECT_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testNewCommitWithBarelyOverflowingSubjectLine() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there what is going on now and what will happen when I overflows"
		XCTAssertGreaterThan(newContent.count, OVERFLOW_SUBJECT_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		XCTAssertEqual(overflowRanges[0], OVERFLOW_SUBJECT_THRESHOLD ..< OVERFLOW_SUBJECT_THRESHOLD + 1)
	}
	
	func testNewCommitWithLongOverflowingSubjectLine() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there what is going on now and what will happen when I overflow the text here"
		XCTAssertGreaterThan(newContent.count, OVERFLOW_SUBJECT_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		XCTAssertEqual(overflowRanges[0], OVERFLOW_SUBJECT_THRESHOLD ..< newContent.count)
	}
	
	func testNewCommitWithNoOverflowingBody() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello what"
		let body = "What is going on here."
		
		let newContent = "\(subject)\n\(body)"
		XCTAssertLessThan(body.count, OVERFLOW_BODY_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testNewCommitWithAlmostOverflowingBody() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello what"
		let body = "Hello there what is going on now and what will happen when I overflowsss"
		
		let newContent = "\(subject)\n\(body)"
		XCTAssertEqual(body.count, OVERFLOW_BODY_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testNewCommitWithBarelyOverflowingBody() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello what"
		let body = "Hello there what is going on now and what will happen when I overflowsssz"
		
		let newContent = "\(subject)\n\(body)"
		XCTAssertGreaterThan(body.count, OVERFLOW_BODY_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		let location = subject.count + "\n\n".count + OVERFLOW_BODY_THRESHOLD
		XCTAssertEqual(overflowRanges[0], location ..< location + 1)
	}
	
	func testNewCommitWithLongOverflowingBody() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello what"
		let body = "Hello there what is going on now and what will happen when I overflow this section"
		
		let newContent = "\(subject)\n\(body)"
		XCTAssertGreaterThan(body.count, OVERFLOW_BODY_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		let lineLocation = subject.count + "\n\n".count
		XCTAssertEqual(overflowRanges[0], (lineLocation + OVERFLOW_BODY_THRESHOLD) ..< (lineLocation + body.count))
	}
	
	func testNewCommitWithMultipleOverflowingLines() throws {
		let app = try KometApp(filename: "new-commit")

		let subject = "Hello there what is going on now and what will happen when I overflow the text here"
		XCTAssertGreaterThan(subject.count, OVERFLOW_SUBJECT_THRESHOLD)
		
		let body1 = "Okay then."
		XCTAssertLessThan(body1.count, OVERFLOW_BODY_THRESHOLD)
		
		let body2 = "Let us overflow this text like nobody has ever done before when the application was written again!!!"
		XCTAssertGreaterThan(body2.count, OVERFLOW_BODY_THRESHOLD)
		
		let body3 = "\n"
		let body4 = "Okay, that is nice I guess."
		XCTAssertLessThan(body4.count, OVERFLOW_BODY_THRESHOLD)
		
		let body5 = "Okay, this is going to overflow text again and is going to test the overflow range I suppose..........."
		XCTAssertGreaterThan(body5.count, OVERFLOW_BODY_THRESHOLD)
		
		let body6 = "# Since this is a comment, I believe there should be no overflow here.. THis is a good thing to test out really\n"
		XCTAssertGreaterThan(body6.count, OVERFLOW_BODY_THRESHOLD)
		
		app.typeText(subject + "\n")
		
		let bodyContent = [body1, body2, body3, body4, body5, body6].joined(separator: "\n")
		app.typeText(bodyContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 3)
		
		do {
			XCTAssertEqual(overflowRanges[0], OVERFLOW_SUBJECT_THRESHOLD ..< subject.count)
		}
		
		do {
			let lineLocation = subject.count + "\n\n".count + body1.count + "\n".count
			
			XCTAssertEqual(overflowRanges[1], (lineLocation + OVERFLOW_BODY_THRESHOLD) ..< (lineLocation + body2.count))
		}
		
		do {
			let skipCount = subject.count + "\n\n".count + [body1, body2, body3, body4].joined(separator: "\n").count + "\n".count
			
			XCTAssertEqual(overflowRanges[2], (skipCount + OVERFLOW_BODY_THRESHOLD) ..< (skipCount + body5.count))
		}
	}
	
	func testNoSubjectOverflowAfterDeletion() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there what is going on now and what will happen when I overflow the text here"
		XCTAssertGreaterThan(subject.count, OVERFLOW_SUBJECT_THRESHOLD)
		
		app.typeText(subject)
		app.deleteText(count: subject.count - OVERFLOW_SUBJECT_THRESHOLD)
		
		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testSubjectOverflowAfterDeletion() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there what is going on now and what will happen when I overflow the text here"
		XCTAssertGreaterThan(subject.count, OVERFLOW_SUBJECT_THRESHOLD)
		
		app.typeText(subject)
		app.deleteText(count: subject.count - OVERFLOW_SUBJECT_THRESHOLD - 1)
		
		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		let location = OVERFLOW_SUBJECT_THRESHOLD
		XCTAssertEqual(overflowRanges[0], location ..< location + 1)
	}
	
	func testNoBodyOverflowAfterDeletion() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there"
		XCTAssertLessThan(subject.count, OVERFLOW_SUBJECT_THRESHOLD)
		
		let body = "Hello there what is going on now and what will happen when I overflow the text here ayyy!!!!!"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body)
		
		app.deleteText(count: body.count - OVERFLOW_BODY_THRESHOLD)
		
		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 0)
	}
	
	func testBodyOverflowAfterDeletion() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there"
		XCTAssertLessThan(subject.count, OVERFLOW_SUBJECT_THRESHOLD)
		
		let body = "Hello there what is going on now and what will happen when I overflow the text here ayyy!!!!!"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body)
		
		app.deleteText(count: body.count - OVERFLOW_BODY_THRESHOLD - 1)
		
		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		let location = subject.count + "\n\n".count + OVERFLOW_BODY_THRESHOLD
		XCTAssertEqual(overflowRanges[0], location ..< location + 1)
	}
	
	// MARK: Comments
	
	func testNoEditingBeginningOfComments() throws {
		let app = try KometApp(filename: "new-commit")
		
		app.moveCursorDown(count: 1)
		
		app.typeText("This should fail")
		app.typeText("\n")
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(app.initialContent, newContent)
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
	}
	
	func testNoEditingMiddleOfComments() throws {
		let app = try KometApp(filename: "new-commit")
		
		app.moveCursorDown(count: 2)
		app.moveCursorRight(count: 3)
		
		app.typeText("This should fail")
		app.typeText("\n")
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(app.initialContent, newContent)
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
	}
	
	func testNoEditingEndOfComments() throws {
		let app = try KometApp(filename: "new-commit")
		
		app.moveCursorDown(count: app.initialContent.components(separatedBy: "\n").count + 1)
		
		app.typeText("This should fail")
		app.typeText("\n")
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(app.initialContent, newContent)
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
	}
	
	func testAddingCommentContent() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there!"
		let body1 = "# This is kind of like a comment line!"
		let body2 = "tada!"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body1)
		app.typeText("\n")
		app.typeText(body2)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let commentLineRanges = breadcrumbs!.commentLineRanges
		XCTAssertEqual(commentLineRanges.count, 1)
		
		let lineLocation = subject.count + "\n\n".count
		XCTAssertEqual(commentLineRanges[0], lineLocation ..< lineLocation + body1.count)
	}
	
	func testDeletingCommentContent() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello there!"
		let body1 = "# This is kind of like a comment line!"
		let body2 = "tada!"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body1)
		app.typeText("\n")
		app.typeText(body2)
		
		app.moveCursorLeft(count: body2.count - 1)
		app.moveCursorUp(count: 1)
		app.deleteText(count: 1)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let commentLineRanges = breadcrumbs!.commentLineRanges
		XCTAssertEqual(commentLineRanges.count, 0)
	}
	
	// MARK: Non-version controlled file
	
	func testAllowEditingCommentSectionAtEnd() throws {
		let app = try KometApp(filename: "new-commit", versionControlledFile: false)
		
		app.moveCursorDown(count: app.initialContent.components(separatedBy: "\n").count + 1)
		
		let newBodyContent = "\nThis should succeed\n"
		app.typeText(newBodyContent)
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(app.initialContent + newBodyContent, newContent)
	}
	
	func testAllowEditingCommentSectionAtBeginningContent() throws {
		let app = try KometApp(filename: "amended-commit", versionControlledFile: false)
		
		let subject = "Hello"
		app.typeText(subject)
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(subject + app.initialContent, newContent)
	}
	
	func testAllowEditingCommentSectionAtMiddle() throws {
		let app = try KometApp(filename: "new-commit", versionControlledFile: false)
		
		app.moveCursorDown(count: 3)
		app.moveCursorRight(count: 1)
		app.deleteText(count: 1)
		
		let body = "Hello"
		app.typeText(body)
		
		let lineComponents = app.initialContent.components(separatedBy: "\n")
		let newLineComponents = lineComponents[0 ..< 3] + [body] + lineComponents[4 ..< lineComponents.count]
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(newLineComponents.joined(separator: "\n"), newContent)
	}
	
	func testAllowEditingCommentSectionSelection() throws {
		let app = try KometApp(filename: "new-commit", versionControlledFile: false)
		
		app.selectAll()
		
		let content = "Hello"
		app.typeText(content)
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(content, newContent)
	}
	
	func testNonVersionControlledFileLengthWarningsAndAutomaticInsertion() throws {
		let app = try KometApp(filename: "new-commit", versionControlledFile: false)
		
		let line = "Hello this is a line that will be exceed many characters very very very very long okay"
		let content = line + "\n" + line
		app.typeText(content)
		
		let (breadcrumbs, newContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(breadcrumbs!.textOverflowRanges.count, 0)
		XCTAssertEqual(content + app.initialContent, newContent)
	}
	
	func testNonVersionControlledFileResumeIncompleteSessionAndEmptyContent() throws {
		let app = try KometApp(filename: "new-commit", resumeIncompleteSession: true, versionControlledFile: false)
		
		let subject = "Hello there!"
		app.typeText(subject)
		
		// Canceling a non-version controlled file commit should result in a exit(1)
		let (cancelBreadcrumbs, _) = try app.cancel()
		XCTAssertNotEqual(cancelBreadcrumbs!.exitStatus, 0)
		
		// Test that the content was not restored and we can commit an empty messsage
		app.relaunch()
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(app.initialContent, finalContent)
	}
	
	// MARK: Hg & Svn
	
	func testNewHgCommit() throws {
		let app = try KometApp(filename: "hg-new-commit")
		
		let subject = "Hello there"
		app.typeText(subject)
		
		app.moveCursorDown(count: 6)
		app.typeText("test")
		
		app.moveCursorRight(count: 4)
		app.typeText("blah")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let finalLineComponents = finalContent.components(separatedBy: "\n")
		let initialLineComponents = app.initialContent.components(separatedBy: "\n")
		
		XCTAssertEqual(finalLineComponents[0], subject)
		XCTAssertEqual(initialLineComponents[1 ..< initialLineComponents.count], finalLineComponents[1 ..< initialLineComponents.count])
	}
	
	func testAddingHgCommentContent() throws {
		let app = try KometApp(filename: "hg-new-commit")
		
		let subject = "Hello there"
		app.typeText(subject + "\n")
		
		let commentLine = "HG: Here is a comment line"
		app.typeText(commentLine + "\n")
		
		let secondLine = "Here is a normal line"
		app.typeText(secondLine)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let commentLineRanges = breadcrumbs!.commentLineRanges
		XCTAssertEqual(commentLineRanges.count, 1)
		
		let commentLineLocation = subject.count + "\n\n".count
		XCTAssertEqual(commentLineRanges[0], commentLineLocation ..< commentLineLocation + commentLine.count)
		
		let finalLineComponents = finalContent.components(separatedBy: "\n")
		let initialLineComponents = app.initialContent.components(separatedBy: "\n")
		
		XCTAssertEqual(finalLineComponents[0], subject)
		XCTAssertEqual(finalLineComponents[1], "")
		XCTAssertEqual(finalLineComponents[2], commentLine)
		XCTAssertEqual(finalLineComponents[3], secondLine)
		
		XCTAssertEqual(initialLineComponents[1 ..< initialLineComponents.count], finalLineComponents[4 ..< finalLineComponents.count])
	}
	
	func testHgRebaseEditing() throws {
		let app = try KometApp(filename: "hg-histedit")
		
		app.selectAll()
		app.deleteText(count: 1)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let finalLineComponents = finalContent.components(separatedBy: "\n")
		let initialLineComponents = app.initialContent.components(separatedBy: "\n")
		
		XCTAssertEqual([""] + initialLineComponents[3 ..< initialLineComponents.count], finalLineComponents[0 ..< finalLineComponents.count])
	}
	
	func testNewSvnCommit() throws {
		let app = try KometApp(filename: "svn-new-commit")
		
		let subject = "Hello there"
		app.typeText(subject)
		
		app.moveCursorDown(count: 2)
		app.typeText("test")
		
		app.moveCursorRight(count: 2)
		app.typeText("blah")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let finalLineComponents = finalContent.components(separatedBy: "\n")
		let initialLineComponents = app.initialContent.components(separatedBy: "\n")
		
		XCTAssertEqual(finalLineComponents[0], subject)
		XCTAssertEqual(initialLineComponents[1 ..< initialLineComponents.count], finalLineComponents[1 ..< initialLineComponents.count])
	}
	
	// MARK: Emoji
	
	func testInsertingEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "🥳 Happy birthday!"
		app.typeText(subject)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		XCTAssertEqual(subject + app.initialContent, finalContent)
	}
	
	func testSubjectLimitWithEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello this is a line that will be exactly 69 characters long and yep📝"
		app.typeText(subject)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(breadcrumbs!.textOverflowRanges.count, 0)
	}
	
	func testSubjectExceedingLimitWithEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		
		let emoji = "📝"
		let subject = "Hello this is a line that will be exactly 69 characters long and yepa\(emoji)"
		app.typeText(subject)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let textOverflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(textOverflowRanges.count, 1)
		
		XCTAssertEqual(textOverflowRanges[0], (subject.utf16.count - emoji.utf16.count) ..< subject.utf16.count)
	}
	
	func testBodyLimitWithEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		
		let subject = "Hello"
		let body = "Hello this is a line that will be exactly 72 characters long and yepppp📝"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(breadcrumbs!.textOverflowRanges.count, 0)
	}
	
	func testBodyExceedingLimitWithEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		
		let emoji = "📝"
		let subject = "Hello"
		let body = "Hello this is a line that will be exactly 72 characters long and yeppppa\(emoji)"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let textOverflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(textOverflowRanges.count, 1)
		
		let lineLocation = subject.utf16.count + "\n\n".utf16.count
		XCTAssertEqual(textOverflowRanges[0], (lineLocation + body.utf16.count - emoji.utf16.count) ..< (lineLocation + body.utf16.count))
	}
	
	func testCommentLineWithEmoji() throws {
		let app = try KometApp(filename: "new-commit")
		let subject = "Hello"
		let emoji = "📝"
		let body = "# \(emoji) This is a comment line with see"
		let body2 = "Okay"
		
		app.typeText(subject)
		app.typeText("\n")
		app.typeText(body)
		app.typeText("\n")
		app.typeText(body2)
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let commentLineRanges = breadcrumbs!.commentLineRanges
		XCTAssertEqual(commentLineRanges.count, 1)
		
		let lineLocation = subject.utf16.count + "\n\n".utf16.count
		XCTAssertEqual(commentLineRanges[0], lineLocation ..< lineLocation + body.utf16.count)
	}
	
	// MARK: Performance
	
	func testLargeFileCommit() throws {
		let app = try KometApp(filename: "linux-partial")
		
		let subject = "Hello there!"
		let body = "I hope this works pretty well!!!!"
		
		app.typeText(subject + "\n")
		
		measure {
			app.typeText(body + "\n")
		}
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
	}
	
	func testLargeNonVersionControlledFileCommit() throws {
		let app = try KometApp(filename: "linux-partial", versionControlledFile: false)
		
		let subject = "Hello there!"
		let body = "I hope this works pretty well!!!!"
		
		app.typeText(subject + "\n")
		
		measure {
			app.typeText(body + "\n")
		}
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
	}
	
	func testAppLaunchPerformance() throws {
		measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
			let app = try! KometApp(filename: "new-commit")
			let _ = try! app.commit()
		}
	}
	
	func testAppLaunchLargeFilePerformance() throws {
		measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
			let app = try! KometApp(filename: "linux-partial")
			let _ = try! app.commit()
		}
	}
	
	// MARK: Rebasing
	
	func testRebaseWithNoAutomaticNewline() throws {
		let app = try KometApp(filename: "interactive-rebase")
		
		let newBody1 = "\n"
		let newBody2 = "squash ..."
		
		app.typeText(newBody1)
		app.typeText(newBody2)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(breadcrumbs!.textOverflowRanges.count, 0)
		
		let initialLines = app.initialContent.components(separatedBy: "\n")
		XCTAssertTrue(initialLines[4].hasPrefix("# Rebase"), "\(initialLines[4]) does not have rebase comment prefix")
		
		let newLines = initialLines[0 ..< 3] + [newBody2] + initialLines[3 ..< initialLines.count]
		
		XCTAssertEqual(newLines.joined(separator: "\n"), finalContent)
	}
	
	func testNonRebaseSpellChecking() throws {
		let app = try KometApp(filename: "amended-commit")
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertTrue(breadcrumbs!.spellChecking, "Spell checking is disabled")
	}
	
	func testRebase1SpellChecking() throws {
		let app = try KometApp(filename: "interactive-rebase")
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertFalse(breadcrumbs!.spellChecking, "Spell checking is enabled")
	}
	
	func testRebase2SpellChecking() throws {
		let app = try KometApp(filename: "interactive-rebase-2")
		
		let (breadcrumbs, _) = try app.commit()
		XCTAssertFalse(breadcrumbs!.spellChecking, "Spell checking is enabled")
	}
	
	func testRebaseEditing() throws {
		let app = try KometApp(filename: "interactive-rebase-2")
		
		let newBody1 = "Here is some new content"
		let newBody2 = "Here is some more new content"
		
		app.typeText("\n")
		app.typeText(newBody1)
		app.moveCursorUp(count: 4)
		app.typeText(newBody2)
		app.moveCursorDown(count: 8)
		app.typeText("No-op text")
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let initialLines = app.initialContent.components(separatedBy: "\n")
		let newLines = initialLines[0 ..< 4] + [newBody2] + initialLines[5 ..< 8] + [newBody1 + "\n"] + initialLines[9 ..< initialLines.count]
		
		XCTAssertEqual(newLines.joined(separator: "\n"), finalContent)
	}
	
	func testRebaseSelection() throws {
		let app = try KometApp(filename: "interactive-rebase-2")
		
		let subject = "Hello!"
		
		app.selectAll()
		app.typeText(subject)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
		let initialLines = app.initialContent.components(separatedBy: "\n")
		let newLines = [subject + "\n"] + initialLines[9 ..< initialLines.count]
		
		XCTAssertEqual(newLines.joined(separator: "\n"), finalContent)
	}
	
	// MARK: Resume Session
	
	func testResumingIncompleteSession() throws {
		let app = try KometApp(filename: "new-commit", resumeIncompleteSession: true)
		
		let subject = "Hello there!"
		app.typeText(subject)
		
		let _ = try app.cancel()
		
		// Test that the content was initially all selected
		app.relaunch()
		app.moveCursorLeft(count: 1)
		
		let preSubject = "Why "
		app.typeText(preSubject)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(preSubject + subject + app.initialContent, finalContent)
	}
	
	func testResumingIncompleteSessionDisabled() throws {
		let app = try KometApp(filename: "new-commit", resumeIncompleteSession: false)
		
		let subject = "Hello there!"
		app.typeText(subject)
		
		let _ = try app.cancel()
		
		app.relaunch()
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		XCTAssertEqual(app.initialContent, finalContent)
	}
}
