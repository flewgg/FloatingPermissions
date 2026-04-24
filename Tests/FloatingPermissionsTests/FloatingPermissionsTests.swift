import Testing
@testable import FloatingPermissions

@Test func moduleNameIsStable() {
    #expect(String(describing: FloatingPermissions.self) == "FloatingPermissions")
}
