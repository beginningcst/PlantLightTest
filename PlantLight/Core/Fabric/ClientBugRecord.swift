
import Foundation

public struct ClientBugRecord: LocalizedError {

    var desc = ""

    var reason = ""
    
    var suggestion = ""
    
    var help = ""
    
    public var errorDescription: String? {
        return desc
    }
    
    public var failureReason: String? {
        return reason
    }
    
    public var recoverySuggestion: String? {
        return suggestion
    }
    
    public var helpAnchor: String? {
        return help
    }
    
    public init(_ desc: String) {
        self.desc = desc
    }
}
