import SwiftUI
import ParseSwift

/// Comment section for one post: shows each commenter's username and comment.
struct CommentsView: View {
    let post: Post

    @Environment(\.dismiss) private var dismiss
    @State private var comments: [Comment] = []
    @State private var newText = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else if comments.isEmpty {
                    Text("No comments yet. Be the first!")
                        .foregroundStyle(.gray)
                        .frame(maxHeight: .infinity)
                } else {
                    List(comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.user?.username ?? "Unknown").bold()
                                Spacer()
                                if let date = comment.createdAt {
                                    Text(date.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                            Text(comment.text ?? "")
                        }
                        .listRowBackground(Color.black)
                    }
                    .listStyle(.plain)
                }

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red).padding(.horizontal)
                }

                HStack(spacing: 10) {
                    TextField("Add a comment…", text: $newText)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Button {
                        Task { await send() }
                    } label: {
                        if isSending { ProgressView() } else { Image(systemName: "paperplane.fill") }
                    }
                    .disabled(trimmedText.isEmpty || isSending)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private var trimmedText: String {
        newText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func load() async {
        defer { isLoading = false }
        do {
            let pointer = try post.toPointer()
            comments = try await Comment.query("post" == pointer)
                .include("user")
                .order([.ascending("createdAt")])
                .find()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func send() async {
        guard !trimmedText.isEmpty else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            var comment = Comment()
            comment.text = trimmedText
            comment.user = User.current
            comment.post = try post.toPointer()

            var saved = try await comment.save()
            saved.user = User.current   // so the username shows right away
            comments.append(saved)
            newText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
