//
//  KometUITests.swift
//  KometUITests
//
//  Created by Mayur Pawashe on 10/4/20.
//  Copyright © 2020 zgcoder. All rights reserved.
//

import XCTest

let OVERFLOW_SUBJECT_THRESHOLD = 69
let OVERFLOW_BODY_THRESHOLD = 72

class KometApp {
	let initialContent: String
	private let textView: XCUIElement
	
	private let pid: pid_t
	private let application: XCUIApplication
	private let fileURL: URL
	private let tempDirectoryURL: URL
	private let breadcrumbsURL: URL
	
	init(filename: String, automicNewlineInsertion: Bool = true, resumeIncompleteSession: Bool = false) throws {
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
		
		let appIdentifier = "org.zgcoder.Komet"
		
		let runningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: appIdentifier)
		
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
			 key(ZGWindowStyleThemeKey), String(0),
			 key(ZGWindowVibrancyKey), String(false),
			 key(ZGMessageFontNameKey), "",
			 key(ZGMessageFontPointSizeKey), String(0.0),
			 key(ZGCommentsFontNameKey), "",
			 key(ZGCommentsFontPointSizeKey), String(0.0),
			 key(ZGCommitTextViewContinuousSpellCheckingKey), String(true),
			 key(ZGCommitTextViewAutomaticSpellingCorrectionKey), String(false),
			 key(ZGCommitTextViewAutomaticTextReplacementKey), String(false),
			 key(ZGBreadcrumbsURLKey), breadcrumbsURL.path]
		application.launch()
		
		let newRunningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: appIdentifier)
		
		let runningApplication = newRunningApplications.first { newRunningApplication -> Bool in
			!runningApplications.contains(newRunningApplication)
		}!
		
		pid = runningApplication.processIdentifier
		textView = application.windows.textViews.element
	}
	
	deinit {
		let _ = try? FileManager.default.removeItem(at: tempDirectoryURL)
	}
	
	private func waitForExit() throws -> (ZGBreadcrumbs?, String) {
		var status: Int32 = 0
		waitpid(pid, &status, 0)
		
		let breadcrumbs = ZGBreadcrumbs(readingFrom: breadcrumbsURL)
		
		let finalContent = try String(contentsOf: fileURL)
		return (breadcrumbs, finalContent)
	}
	
	func commit() throws -> (ZGBreadcrumbs?, String) {
		application.menuBars.menuBarItems["File"].menuItems["Commit"].click()
		return try waitForExit()
	}
	
	func cancel() throws -> (ZGBreadcrumbs?, String) {
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
				textView.typeText(String(line))
			}
			textView.typeText("\n")
			currentText = String(currentText[currentText.index(newlineIndex, offsetBy: 1) ..< currentText.endIndex])
		}
		
		if currentText.count > 0 {
			textView.typeText(currentText)
		}
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
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(OVERFLOW_SUBJECT_THRESHOLD, 1))
	}
	
	func testNewCommitWithLongOverflowingSubjectLine() throws {
		let app = try KometApp(filename: "new-commit")

		let newContent = "Hello there what is going on now and what will happen when I overflow the text here"
		XCTAssertGreaterThan(newContent.count, OVERFLOW_SUBJECT_THRESHOLD)
		app.typeText(newContent)

		let (breadcrumbs, _) = try app.commit()
		let overflowRanges = breadcrumbs!.textOverflowRanges
		XCTAssertEqual(overflowRanges.count, 1)
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(OVERFLOW_SUBJECT_THRESHOLD, newContent.count - OVERFLOW_SUBJECT_THRESHOLD))
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
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(subject.count + "\n\n".count + OVERFLOW_BODY_THRESHOLD, 1))
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
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(subject.count + "\n\n".count + OVERFLOW_BODY_THRESHOLD, body.count - OVERFLOW_BODY_THRESHOLD))
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
			let rangeObject = overflowRanges[0] as! NSValue
			let range = rangeObject.rangeValue
			
			XCTAssertEqual(range, NSMakeRange(OVERFLOW_SUBJECT_THRESHOLD, subject.count - OVERFLOW_SUBJECT_THRESHOLD))
		}
		
		do {
			let rangeObject = overflowRanges[1] as! NSValue
			let range = rangeObject.rangeValue
			
			XCTAssertEqual(range, NSMakeRange(subject.count + "\n\n".count + body1.count + "\n".count + OVERFLOW_BODY_THRESHOLD, body2.count - OVERFLOW_BODY_THRESHOLD))
		}
		
		do {
			let rangeObject = overflowRanges[2] as! NSValue
			let range = rangeObject.rangeValue
			
			let skipCount = subject.count + "\n\n".count + [body1, body2, body3, body4].joined(separator: "\n").count + "\n".count
			
			XCTAssertEqual(range, NSMakeRange(skipCount + OVERFLOW_BODY_THRESHOLD, body5.count - OVERFLOW_BODY_THRESHOLD))
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
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(OVERFLOW_SUBJECT_THRESHOLD, 1))
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
		
		let rangeObject = overflowRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(subject.count + "\n\n".count + OVERFLOW_BODY_THRESHOLD, 1))
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
		
		let rangeObject = commentLineRanges[0] as! NSValue
		let range = rangeObject.rangeValue
		
		XCTAssertEqual(range, NSMakeRange(subject.count + "\n\n".count, body1.count))
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
		
		let commentLineRange = commentLineRanges[0] as! NSValue
		XCTAssertEqual(commentLineRange.rangeValue, NSMakeRange(subject.count + "\n\n".count, commentLine.count))
		
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
	
	// MARK: Large file
	
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
	
	// MARK: Rebasing
	
	func testRebaseWithNoAutomaticNewline() throws {
		let app = try KometApp(filename: "interactive-rebase")
		
		let newBody1 = "\n"
		let newBody2 = "squash ..."
		
		app.typeText(newBody1)
		app.typeText(newBody2)
		
		let (breadcrumbs, finalContent) = try app.commit()
		XCTAssertEqual(breadcrumbs!.exitStatus, 0)
		
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
