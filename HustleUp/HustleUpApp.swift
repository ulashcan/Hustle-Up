import SwiftUI

@main
struct HustleUpApp: App {
    @State private var model: AppModel

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = AppEnvironment.bootstrap(arguments: arguments)
        _model = State(initialValue: AppModel(environment: environment, arguments: arguments))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
        }
    }
}
