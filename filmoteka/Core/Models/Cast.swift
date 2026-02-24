import Foundation

struct CastMember: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let knownForDepartment: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
    }
}

struct MovieCreditsResponse: Codable, Sendable {
    let cast: [CastMember]
}

extension Array where Element == CastMember {
    var actorsOnly: [CastMember] {
        return self.filter { castMember in
            return castMember.knownForDepartment == "Acting"
        }
    }
}
