import SwiftUI

struct SettingsView: View {
    @State private var orientationType: SettingsOrientationType = SettingsManager.sharedManager.settings.orientationType
    @State private var sortType: SettingsSortType = SettingsManager.sharedManager.settings.sortType
    @Binding var showingSettingsModal: Bool

    var body: some View {
        NavigationView {
            Form {
                Picker("orientation", selection: $orientationType) {
                    Text("portrait").tag(SettingsOrientationType.portrait)
                        .accessibility(identifier: "SettingsView_Picker_orientation_portrait")
                    Text("landscape").tag(SettingsOrientationType.landscape)
                        .accessibility(identifier: "SettingsView_Picker_orientation_landscape")
                }
                .accessibility(identifier: "SettingsView_Picker_orientation")
                .onChange(of: orientationType) { newValue in
                    SettingsManager.sharedManager.storeOrientationType(orientationType: orientationType)
                }
                
                Picker("playback order", selection: $sortType) {
                    Text("oldest order").tag(SettingsSortType.date_asc)
                        .accessibility(identifier: "SettingsView_Picker_order_oldest")
                    Text("new order").tag(SettingsSortType.date_desc)
                        .accessibility(identifier: "SettingsView_Picker_order_new")
                    Text("shuffle order").tag(SettingsSortType.shuffle)
                        .accessibility(identifier: "SettingsView_Picker_order_shuffle")
                }
                .accessibility(identifier: "SettingsView_Picker_order")
                .onChange(of: sortType) { newValue in
                    SettingsManager.sharedManager.storeSortType(sortType: sortType)
                }
            }
            .accessibility(identifier: "SettingsView_Form")
            .navigationBarTitle("settings", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(
                    action: {
                        showingSettingsModal = false
                    })
                {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.secondary)
                }
                .accessibility(identifier: "SettingsView_Form_Button_close")
            )
        }
        .accessibility(identifier: "SettingsView_NavigationView")

    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(showingSettingsModal: .constant(true))
        }
    }
}
