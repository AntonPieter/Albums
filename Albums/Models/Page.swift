import Foundation

struct Page<Element: Decodable>: Decodable {
    let data: [Element]
    let total: Int?
}

extension Page: Sendable where Element: Sendable {}
