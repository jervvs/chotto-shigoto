import SwiftUI

#if !DEBUG
import FamilyControls
import ManagedSettings

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection = FamilyActivitySelection()

    var onSelect: (FamilyActivitySelection) -> Void

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Block Apps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            onSelect(selection)
                            dismiss()
                        }
                    }
                }
        }
    }
}
#endif
