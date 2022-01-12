import XCTest

/*
 事前に準備しておくこと
    * 対応デバイス
        * (6.5)iPhone 12 Pro Max
        * (5.5)iPhone 8 Plus
        * (12.9)iPad Pro 第 5 世代
    * シミュレータにサンプル動画をセットアップ
        * sample.movをMacからシミュレータにコピー
        * シミュレータ内で複製して3個にする
        * アルバム一覧（以下順番で作成する、括弧の中はビデオの数）
            * Cat(3)
            * Family(2)
            * Travel(2)
            * Cooking(1)
            * Sports(1)
 AppStore申請用キャプチャ画像の取得はfastlaneを使う（以下コマンドを実行）
    * fastlane snapshot run
 */
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
        let app = XCUIApplication()
        setupSnapshot(app) // setup fastlane
        app.launch()

        //
        // 写真へのアクセス許可
        //
        if app.tables["ContentView_List"].cells.count == 0 {
            // システムアラートを管理している springboard のアプリケーションをキャッチアップ
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            // springboard のアプリケーションにアラートが表示されている想定なので、そこからボタンを検知する
            let systemAllowBtnJP = springboard.buttons.element(boundBy: 1) // 「許可する」ボタン

            // テスト実行中のアプリでもアラートをキャッチし、ボタンを検知する
            let allowBtnJP = app.alerts.firstMatch.buttons.element(boundBy: 1) // 「許可する」ボタン

            // アラートボタンを検知するまで待機
            if systemAllowBtnJP.waitForExistence(timeout: 2) {
                systemAllowBtnJP.tap()
            } else if allowBtnJP.waitForExistence(timeout: 2) {
                allowBtnJP.tap()
            }
        }
        
        //
        // 設定を初期設定に戻す
        //
        
        // SettingsViewを開く
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 「再生時の向き」の入力項目を確認
        app.buttons["SettingsView_Picker_orientation"].tap()
        if !app.switches["SettingsView_Picker_orientation_portrait"].isSelected {
            app.switches["SettingsView_Picker_orientation_portrait"].tap()
        } else {
            app.otherElements["SettingsView_NavigationView"].buttons.element(boundBy: 0).tap()
        }

        // 「再生順」の入力項目を確認
        app.buttons["SettingsView_Picker_order"].tap()
        if !app.switches["SettingsView_Picker_order_oldest"].isSelected {
            app.switches["SettingsView_Picker_order_oldest"].tap()
        } else {
            app.otherElements["SettingsView_NavigationView"].buttons.element(boundBy: 0).tap()
        }

        // SettingsViewを閉じる
        app.buttons["SettingsView_Form_Button_close"].tap()
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
        let videoView = app.otherElements["VideoView_PlayerView1"]
        XCTAssertTrue(videoView.exists)
        videoView.tap()
        snapshot("VideoView")
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

    func testVideoViewTapAction() throws {
        let app = XCUIApplication()
        var tables: XCUIElement
        var backButton: XCUIElement

        // VideoViewをタップして一時停止状態になることを確認
        app.staticTexts.matching(identifier: "ContentView_List_1_Text_title").firstMatch.tap()
        sleep(2)
        let videoView = app.otherElements["VideoView_PlayerView1"]
        XCTAssertTrue(videoView.exists)
        videoView.tap()

        // NavigationBarの戻るボタンが表示されることを確認
        backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        
        // 一定時間経過してもまだ再生が終わっていないことを確認
        sleep(5)
        XCTAssertTrue(videoView.exists)

        // VideoViewをタップして再生を再開する
        videoView.tap()

        // 再生が完了して一覧に戻ることを確認
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 8) {
            XCTFail()
        }
    }

    func testVideoViewSwipeAction() throws {
        let app = XCUIApplication()
        var tables: XCUIElement
        var videoView: XCUIElement

        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeDown() // close
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
            XCTFail()
        }

        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeUp() // close
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
            XCTFail()
        }

        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeLeft() // 0 => 1
        sleep(1)
        videoView.swipeLeft() // 1 => 2
        sleep(1)
        videoView.swipeRight() // 2 => 1
        sleep(1)
        videoView.swipeRight() // 1 => 0
        sleep(1)
        videoView.swipeRight() // 0 => 0
        sleep(1)
        videoView.swipeLeft() // 0 => 1
        sleep(1)
        videoView.swipeLeft() // 1 => 2
        sleep(1)
        videoView.swipeLeft() // 2 => 3(close)
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
            XCTFail()
        }
    }
    
    func testVideoViewSwipeActionOnLandscapeSetting() throws {
        let app = XCUIApplication()
        var tables: XCUIElement
        var videoView: XCUIElement

        // 再生方向を横にする
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["SettingsView_Picker_orientation"].tap()
        app.switches["SettingsView_Picker_orientation_landscape"].tap()
        // SettingsViewを閉じる
        app.buttons["SettingsView_Form_Button_close"].tap()
        
        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeLeft() // close
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
            XCTFail()
        }

        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeRight() // close
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
            XCTFail()
        }

        app.staticTexts.matching(identifier: "ContentView_List_0_Text_title").firstMatch.tap()
        videoView = app.otherElements["VideoView_PlayerView0"]
        videoView.swipeUp() // 0 => 1
        sleep(1)
        videoView.swipeUp() // 1 => 2
        sleep(1)
        videoView.swipeUp() // 2 => 3(close)
        tables = app.tables["ContentView_List"]
        if !tables.waitForExistence(timeout: 2) {
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
