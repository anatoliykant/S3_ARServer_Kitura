import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    public init() throws {
        // Configure logging
        initializeLogging()
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)

        router.all("/public", 
            middleware: StaticFileServer())
	    router.all("/pikachu",
            middleware: StaticFileServer(
                path: "/Users/kant/Documents/Develop/Courses/S3/Part4_ARServer/2019.11.10/S3_ARServer_Kitura/public/Pikachu"))
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: 9000 /*cloudEnv.port*/, with: router)
        Kitura.run()
    }
}