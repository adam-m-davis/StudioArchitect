import Testing
@testable import StudioArchitect

struct ModelTests {

    @Test func sessionStageOrdering() {
        let stages = Session.SessionStage.allCases
        #expect(stages.first == .imported)
        #expect(stages.last == .archived)
        #expect(Session.SessionStage.culled.stepIndex > Session.SessionStage.imported.stepIndex)
    }

    @Test func clientDefaultValues() {
        let client = Client(name: "Test Client")
        #expect(client.type == .personal)
        #expect(!client.id.isEmpty)
    }
}
