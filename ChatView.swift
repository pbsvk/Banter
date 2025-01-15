import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @EnvironmentObject private var databaseService: DatabaseService
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(databaseService.messages) { message in
                        MessageBubble(message: message,
                                     isFromCurrentUser: message.senderId == authService.user?.id)
                    }
                }
                .padding(.horizontal)
            }
            
            // Message input
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(messageText.isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Chat")
        .task {
            do {
                try await databaseService.fetchMessages(for: conversation.id)
            } catch {
                print("Error fetching messages: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        guard let userId = authService.user?.id,
              !messageText.isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        Task {
            do {
                try await databaseService.sendMessage(
                    conversationId: conversation.id,
                    senderId: userId,
                    text: text
                )
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            Text(message.text)
                .padding(12)
                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .cornerRadius(16)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}

// End of file
#Preview{
    ChatView(conversation: Conversation(id: "656", members: ["Vamsi", "Jennny"], lastMessage: "Hello", lastMessageTimestamp: Date()))
        .environmentObject(AuthService(client: AppwriteService.shared.client))
        .environmentObject(DatabaseService(client: AppwriteService.shared.client))
}
