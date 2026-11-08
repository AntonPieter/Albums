import Foundation

struct Page<Element: Decodable>: Decodable {
    let data: [Element]
}
