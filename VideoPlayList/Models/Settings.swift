import Foundation

public enum SettingsOrientationType : Int {
    case portrait = 0
    case landscape = 1
}

public enum SettingsSortType : Int {
    case date_asc = 1
    case date_desc = 2
    case shuffle = 3
}

struct Settings {

    var orientationType: SettingsOrientationType = .portrait
    var sortType: SettingsSortType = .date_asc

}

