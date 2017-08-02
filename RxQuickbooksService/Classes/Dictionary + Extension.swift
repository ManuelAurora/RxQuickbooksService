import Foundation

extension Dictionary
{
    static func += (leftDict: inout Dictionary, rightDict: Dictionary) {
        for (key, value) in rightDict
        {
            leftDict[key] = value
        }
    }
}
