public enum FloatingPermissions {
    /// Creates the object that owns System Settings navigation, window
    /// tracking, and the floating drag panel lifecycle.
    @MainActor
    public static func makeController(
        configuration: FloatingPermissionsConfiguration = .init()
    ) -> FloatingPermissionsController {
        FloatingPermissionsController(configuration: configuration)
    }
}
