import Foundation
import ParseSwift

struct User: ParseUser {
    
    var originalData: Data?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    
    var lastPostedDate: Date?
}

struct Post: ParseObject, Identifiable {
    var originalData: Data?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    var location: String?
    var takenAt: Date?

    var id: String { objectId ?? UUID().uuidString }
}
