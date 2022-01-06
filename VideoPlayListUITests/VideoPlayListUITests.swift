import XCTest

class VideoPlayListUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        // 写真アクセスへの許可メッセージを受け取る
        // Xcode12以降だと反応しない模様
        addUIInterruptionMonitor(withDescription: "Testアラート") { element -> Bool in
            print("OK")
            return true
        }
        
        // UI tests must launch the application that they test.
        // fastlane command : fastlane snapshot run
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // 写真へのアクセス許可
        if app.tables["ContentView_List"].cells.count == 0 {
            // システムアラートを管理している springboard のアプリケーションをキャッチアップ
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            // springboard のアプリケーションにアラートが表示されている想定なので、そこから任意のボタンを検知する
            let buttonLabelTextJP = "すべての写真へのアクセスを許可"
            let systemAllowBtnJP = springboard.buttons[buttonLabelTextJP]

            // テスト実行中のアプリでもアラートをキャッチし、任意のボタンを検知する（ここでは「許可する」ボタン）
            let allowBtnJP = app.alerts.firstMatch.buttons[buttonLabelTextJP]

            // アラートボタンを検知するまで待機
            if systemAllowBtnJP.waitForExistence(timeout: 2) {
                systemAllowBtnJP.tap()
            } else if allowBtnJP.waitForExistence(timeout: 2) {
                allowBtnJP.tap()
            }
        }
        

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testContentView() throws {
        let app = XCUIApplication()
        print(app.debugDescription)
        var tables: XCUIElement
                
        // NagigationBar
        XCTAssertTrue(
            app.navigationBars.staticTexts["ビデオアルバム (5)"].exists ||
            app.navigationBars.staticTexts["Video Albums (5)"].exists)

        // List
        tables = app.tables["ContentView_List"]
        XCTAssertEqual(5, tables.cells.count)
        XCTAssertEqual("Cat", app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.label)
        XCTAssertEqual("3", app.staticTexts.matching(identifier: "ContentView_List_0_Text_count").firstMatch.label)
        XCTAssertEqual("Family", app.staticTexts.matching(identifier: "ContentView_List_1_Text_title").firstMatch.label)
        XCTAssertEqual("2", app.staticTexts.matching(identifier: "ContentView_List_1_Text_count").firstMatch.label)
        XCTAssertEqual("Travel", app.staticTexts.matching(identifier: "ContentView_List_2_Text_title").firstMatch.label)
        XCTAssertEqual("2", app.staticTexts.matching(identifier: "ContentView_List_2_Text_count").firstMatch.label)
        XCTAssertEqual("Cooking", app.staticTexts.matching(identifier: "ContentView_List_3_Text_title").firstMatch.label)
        XCTAssertEqual("1", app.staticTexts.matching(identifier: "ContentView_List_3_Text_count").firstMatch.label)
        XCTAssertEqual("Sports", app.staticTexts.matching(identifier: "ContentView_List_4_Text_title").firstMatch.label)
        XCTAssertEqual("1", app.staticTexts.matching(identifier: "ContentView_List_4_Text_count").firstMatch.label)
        
        snapshot("ContentView")
    }

    func testVideoView() throws {
        let app = XCUIApplication()
        var tables: XCUIElement
        var backButton: XCUIElement

        // 再生直後のNavigationBarが残っている状態で一覧に戻れることを確認
        app.staticTexts.matching(identifier: "ContentView_List_1_Text_title").firstMatch.tap()
        backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        backButton.tap()

        // 一定時間経過後にNavigationBarが消えた状態で一覧に戻れることを確認
        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        // NavigationBarが消えるまで待機
        sleep(2)
        // VideoViewをタップしてNavigationBarを再表示させる
        let videoView = app.otherElements["VideoView_PlayerView"]
        XCTAssertTrue(videoView.exists)
        videoView.tap()
        snapshot("VideoView")
        sleep(1)
        // NavigationBarの戻るボタンが表示されることを確認
        backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        backButton.tap()

        // 再生が完了したら自動で一覧に戻ることを確認
        app.staticTexts.matching(identifier: "ContentView_List_2_Text_title").firstMatch.tap()
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 8) {
            XCTFail()
        }
    }

    func testSettingsView() throws {
        let app = XCUIApplication()
        var picker: XCUIElement
        var backButton: XCUIElement

        let settingsButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()
        
        let forms = app.tables["SettingsView_Form"]
        XCTAssertTrue(forms.exists)

        // 「再生時の向き」の入力項目を確認
        picker = app.buttons["SettingsView_Picker_orientation"]
        XCTAssertTrue(picker.exists)
        picker.tap()
        XCTAssertTrue(app.switches["SettingsView_Picker_orientation_portrait"].exists)
        XCTAssertTrue(app.switches["SettingsView_Picker_orientation_portrait"].isSelected)
        XCTAssertTrue(app.switches["SettingsView_Picker_orientation_landscape"].exists)
        XCTAssertFalse(app.switches["SettingsView_Picker_orientation_landscape"].isSelected)
        backButton = app.otherElements["SettingsView_NavigationView"].buttons.element(boundBy: 0)
        backButton.tap()

        // 「再生時の向き」の入力項目を操作
        picker.tap()
        app.switches["SettingsView_Picker_orientation_landscape"].tap()
        picker.tap()
        XCTAssertFalse(app.switches["SettingsView_Picker_orientation_portrait"].isSelected)
        XCTAssertTrue(app.switches["SettingsView_Picker_orientation_landscape"].isSelected)
        app.switches["SettingsView_Picker_orientation_portrait"].tap()

        // 「再生順」の入力項目を確認
        picker = app.buttons["SettingsView_Picker_order"]
        XCTAssertTrue(picker.exists)
        picker.tap()
        XCTAssertTrue(app.switches["SettingsView_Picker_order_oldest"].exists)
        XCTAssertTrue(app.switches["SettingsView_Picker_order_oldest"].isSelected)
        XCTAssertTrue(app.switches["SettingsView_Picker_order_new"].exists)
        XCTAssertFalse(app.switches["SettingsView_Picker_order_new"].isSelected)
        XCTAssertTrue(app.switches["SettingsView_Picker_order_shuffle"].exists)
        XCTAssertFalse(app.switches["SettingsView_Picker_order_shuffle"].isSelected)
        backButton = app.otherElements["SettingsView_NavigationView"].buttons.element(boundBy: 0)
        backButton.tap()

        // 「再生順」の入力項目を操作
        picker.tap()
        app.switches["SettingsView_Picker_order_shuffle"].tap()
        picker.tap()
        XCTAssertFalse(app.switches["SettingsView_Picker_order_oldest"].isSelected)
        XCTAssertFalse(app.switches["SettingsView_Picker_order_new"].isSelected)
        XCTAssertTrue(app.switches["SettingsView_Picker_order_shuffle"].isSelected)
        app.switches["SettingsView_Picker_order_oldest"].tap()

        // SettingsViewを閉じる
        backButton = app.buttons["SettingsView_Form_Button_close"]
        XCTAssertTrue(backButton.exists)
        backButton.tap()

    }
}
