import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject private var databaseService: DatabaseService
    @EnvironmentObject private var authService: AuthService
    @State private var showingNewConversation = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading conversations...")
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            Task {
                                await fetchConversations()
                            }
                        }
                    }
                    .padding()
                } else if databaseService.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Text("No conversations yet")
                            .font(.headline)
                        Text("Start a new conversation!")
                            .foregroundColor(.gray)
                        Button(action: { showingNewConversation.toggle() }) {
                            Label("New Conversation", systemImage: "square.and.pencil")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List(databaseService.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .refreshable {
                        await fetchConversations()
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewConversation.toggle() }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            do {
                                try await authService.logout()
                            } catch {
                                self.errorMessage = "Failed to log out. Please try again."
                            }
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .task {
            await fetchConversations()
        }
        .sheet(isPresented: $showingNewConversation) {
            NewConversationView()
        }
    }
    
    private func fetchConversations() async {
        guard let userId = authService.user?.id else {
            errorMessage = "User not found. Please try logging in again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await databaseService.fetchConversations(for: userId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load conversations. Please try again."
            print("Error fetching conversations: \(error)")
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.members.joined(separator: ", "))
                .font(.headline)
            if let lastMessage = conversation.lastMessage {
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// End of file
#Preview{
    ConversationListView()
        .environmentObject(AuthService(client: AppwriteService.shared.client))
        .environmentObject(DatabaseService(client: AppwriteService.shared.client))
}
