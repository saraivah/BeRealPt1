import SwiftUI
import ParseSwift

struct FeedView: View {
    @EnvironmentObject var session: SessionStore

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var canLoadMore = true
    @State private var errorMessage: String?

    private let pageSize = 10

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 28) {
                    ForEach(posts) { post in
                        PostCell(post: post)
                            .onAppear {
                                
                                if post.id == posts.last?.id {
                                    Task { await loadMore() }
                                }
                            }
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if posts.isEmpty {
                        Text("No posts yet. Tap + to share your first one.")
                            .foregroundStyle(.gray)
                            .padding(.top, 80)
                    }
                }
                .padding(.vertical)
            }
            .refreshable { await refresh() }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("BeReal.")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Log out") { Task { await session.logOut() } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NewPostView { Task { await refresh() } }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Couldn't load posts",
                   isPresented: .constant(errorMessage != nil),
                   actions: { Button("OK") { errorMessage = nil } },
                   message: { Text(errorMessage ?? "") })
            .task {
                if posts.isEmpty { await refresh() }
            }
        }
    }

    private func query(skip: Int) -> Query<Post> {
        Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .skip(skip)
            .limit(pageSize)
    }

    
    private func refresh() async {
        do {
            let firstPage = try await query(skip: 0).find()
            posts = firstPage
            canLoadMore = firstPage.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }


    private func loadMore() async {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let nextPage = try await query(skip: posts.count).find()
            let existing = Set(posts.compactMap(\.objectId))
            posts += nextPage.filter { !existing.contains($0.objectId ?? "") }
            canLoadMore = nextPage.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PostCell: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(post.user?.username?.prefix(1) ?? "?").uppercased())
                            .bold()
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user?.username ?? "Unknown").bold()
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal)

            AsyncImage(url: post.imageFile?.url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo").font(.largeTitle).foregroundStyle(.gray)
                default:
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3/4, contentMode: .fit)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            if let caption = post.caption, !caption.isEmpty {
                Text(caption).padding(.horizontal)
            }
        }
    }

    
    private var subtitle: String {
        let date = post.takenAt ?? post.createdAt
        let time = date?.formatted(date: .abbreviated, time: .shortened) ?? ""
        if let location = post.location, !location.isEmpty {
            return time.isEmpty ? location : "\(location) · \(time)"
        }
        return time
    }
}
