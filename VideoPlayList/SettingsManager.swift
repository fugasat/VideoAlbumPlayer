import Foundation

class SettingsManager {

    static let sharedManager = SettingsManager()
    private let userDefaults = UserDefaults.standard
    private let storeKeyOrientationType = "orientationType"
    private let storeKeySortType = "sortType"

    var settings: Settings = Settings()

    private init() {
        settings.orientationType = SettingsOrientationType(rawValue: userDefaults.integer(forKey: storeKeyOrientationType)) ?? .portrait
        settings.sortType = SettingsSortType(rawValue: userDefaults.integer(forKey: storeKeySortType)) ?? .date_asc
    }

    func storeOrientationType(orientationType: SettingsOrientationType) {
        settings.orientationType = orientationType
        userDefaults.set(settings.orientationType.rawValue, forKey: storeKeyOrientationType)
    }

    func storeSortType(sortType: SettingsSortType) {
        settings.sortType = sortType
        userDefaults.set(settings.sortType.rawValue, forKey: storeKeySortType)
    }

}

