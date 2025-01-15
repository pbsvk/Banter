import SwiftUI

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var databaseService: DatabaseService
    @EnvironmentObject private var authService: AuthService
    @State private var participants = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Participants")) {
                    TextField("Enter email addresses (comma separated)",
                              text: $participants)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .disabled(isLoading)
                }
                
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Create") { createConversation() }
                    .disabled(participants.isEmpty || isLoading)
            )
        }
    }
    
    private func createConversation() {
        let memberEmails = participants
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !memberEmails.isEmpty else { return }
        guard let currentUser = authService.user else {
            error = "Please log in again"
            return
        }
        
        // Add current user's email if not already included
        var allMembers = Set(memberEmails)
        allMembers.insert(currentUser.email)
        
        isLoading = true
        error = nil
        
        Task {
            do {
                // Convert Set back to Array before creating conversation
                try await databaseService.createConversation(members: Array(allMembers))
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to create conversation: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// End of file
#Preview{
    NewConversationView()
        .environmentObject(AuthService(client: AppwriteService.shared.client))
        .environmentObject(DatabaseService(client: AppwriteService.shared.client))
}
