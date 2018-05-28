import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    func getHelper() -> OpenGithubHelperProtocol {
        let connection = NSXPCConnection(serviceName: "jp.cat-soft.OpenGithubHelper")
        connection.remoteObjectInterface = NSXPCInterface(with: OpenGithubHelperProtocol.self)
        connection.resume()
        return connection.remoteObjectProxy as! OpenGithubHelperProtocol
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        fatalError("Should implement it in sub class")
    }
}

class OpenGitHubCommand: SourceEditorCommand {
    override func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        var line: String = ""
        let selections: [XCSourceTextRange]? = invocation.buffer.selections as? [XCSourceTextRange]
        if let selections = selections {
            if selections[0].start.line != selections[0].end.line ||
                selections[0].start.column != selections[0].end.column {
                let start = selections[0].start.line + 1
                let end = selections[0].end.column > 0 ? selections[0].end.line + 1 : selections[0].end.line
                line = (start != end) ? "L\(start)-L\(end)" : "L\(start)"
            }
        }
        
        let helper = getHelper()
        let semaphore = DispatchSemaphore(value: 0)
        helper.open(with: line) {
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
        completionHandler(nil)
    }
}

class OpenPRCommand: SourceEditorCommand {
    override func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        var line = 0
        let textBuffer = invocation.buffer
        if let selection = textBuffer.selections.firstObject as? XCSourceTextRange {
            line = selection.start.line + 1
        }
        
        let helper = getHelper()
        let semaphore = DispatchSemaphore(value: 0)
        helper.openPR(with: String(line)) {
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5)
        completionHandler(nil)
    }
}
