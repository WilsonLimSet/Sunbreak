import SwiftUI
import FamilyControls
import SwiftData

struct AppsSelectionView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var showingPicker = false
    @State private var showingBedtimeAlert = false
    @Query private var selectionRecords: [SelectionRecord]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var scheduleManager = ScheduleManager.shared
    
    var currentSelection: SelectionRecord? {
        selectionRecords.first
    }
    
    var isRemovalDisabled: Bool {
        scheduleManager.isInBedtime && !scheduleManager.isDayUnlocked
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isRemovalDisabled {
                    // Bedtime restriction banner
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.white)
                        Text("App removal disabled during bedtime")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.9))
                }

                // Add Apps button - always visible
                HStack {
                    Spacer()
                    Button(action: {
                        showingPicker = true
                    }) {
                        Label("Add Apps", systemImage: "plus.app")
                            .fontWeight(.medium)
                            .foregroundColor(Color("BrandOrange"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("BrandOrange").opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if selection.applicationTokens.isEmpty &&
                   selection.categoryTokens.isEmpty &&
                   selection.webDomainTokens.isEmpty {
                    EmptySelectionView(
                        showingPicker: $showingPicker,
                        isDisabled: false,
                        showingBedtimeAlert: $showingBedtimeAlert
                    )
                } else {
                    SelectedItemsList(
                        selection: selection,
                        showingPicker: $showingPicker,
                        isDisabled: isRemovalDisabled,
                        showingBedtimeAlert: $showingBedtimeAlert
                    )
                }
            }
            .navigationTitle("Restricted Apps")
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            .onChange(of: selection) { oldSelection, newSelection in
                // Allow adding apps but not removing during bedtime
                if isRemovalDisabled {
                    // Check if apps were removed
                    let oldApps = oldSelection.applicationTokens
                    let newApps = newSelection.applicationTokens
                    if newApps.count < oldApps.count {
                        // Apps were removed, revert the change
                        showingBedtimeAlert = true
                        selection = oldSelection
                        return
                    }
                }
                saveSelection(newSelection)
            }
            .onAppear {
                loadCurrentSelection()
            }
            .alert("Bedtime Mode Active", isPresented: $showingBedtimeAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot remove app restrictions during bedtime hours. You can add more apps to block, but removal is disabled until morning.")
            }
        }
    }
    
    private func loadCurrentSelection() {
        if let record = currentSelection,
           let savedSelection = record.familyActivitySelection {
            selection = savedSelection
        }
    }
    
    private func saveSelection(_ newSelection: FamilyActivitySelection) {
        
        if let record = currentSelection {
            record.familyActivitySelection = newSelection
        } else {
            let newRecord = SelectionRecord(selection: newSelection)
            modelContext.insert(newRecord)
        }
        
        do {
            try modelContext.save()
            ScheduleManager.shared.saveSelection(newSelection)
            
            // Apply immediately if in bedtime
            if ScheduleManager.shared.isInBedtime && !ScheduleManager.shared.isDayUnlocked {
                ScheduleManager.shared.applyShields(for: newSelection)
            }
        } catch {
            Logger.shared.log("Failed to save selection: \(error)")
        }
    }
}

struct EmptySelectionView: View {
    @Binding var showingPicker: Bool
    let isDisabled: Bool
    @Binding var showingBedtimeAlert: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "apps.iphone.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Apps Selected")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose apps to restrict during bedtime")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { 
                showingPicker = true
            }) {
                Label("Select Apps", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("BrandOrange"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct SelectedItemsList: View {
    let selection: FamilyActivitySelection
    @Binding var showingPicker: Bool
    let isDisabled: Bool
    @Binding var showingBedtimeAlert: Bool
    
    var body: some View {
        List {
            if !selection.applicationTokens.isEmpty {
                Section("Apps") {
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundColor(Color("BrandOrange"))
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selection.applicationTokens.count) app\(selection.applicationTokens.count == 1 ? "" : "s") blocked")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Individual apps selected for restriction")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if !selection.categoryTokens.isEmpty {
                Section("Categories") {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selection.categoryTokens.count) categor\(selection.categoryTokens.count == 1 ? "y" : "ies") blocked")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("App categories selected for restriction")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if !selection.webDomainTokens.isEmpty {
                Section("Websites") {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selection.webDomainTokens.count) website\(selection.webDomainTokens.count == 1 ? "" : "s") blocked")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Web domains selected for restriction")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Restrictions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        StatBadge(
                            count: selection.applicationTokens.count,
                            label: "Apps",
                            color: Color("BrandOrange")
                        )
                        
                        StatBadge(
                            count: selection.categoryTokens.count,
                            label: "Categories",
                            color: .blue
                        )
                        
                        StatBadge(
                            count: selection.webDomainTokens.count,
                            label: "Sites",
                            color: .green
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
