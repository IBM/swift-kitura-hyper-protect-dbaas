import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

// Service imports
import MongoKitten

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

class ApplicationServices {
    // Initialize services
    public let mongoDBService: MongoKitten.MongoDatabase

    public init(cloudEnv: CloudEnv) throws {
        // Run service initializers
        mongoDBService = try initializeServiceHypersecureDbaasMongodb(cloudEnv: cloudEnv)
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    let swaggerPath = projectPath + "/definitions/swiftkiturahyperprotectdbaas.yaml"
    let services: ApplicationServices

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
        // Services
        services = try ApplicationServices(cloudEnv: cloudEnv)
    }

    func postInit() throws {
        // Middleware
        router.all(middleware: StaticFileServer())
        // Endpoints
        initializeAppRoutes(app: self)
        initializeHealthRoutes(app: self)
        initializeProducts_Routes(app: self)
        initializeSwaggerRoutes(app: self)
        initializeErrorRoutes(app: self)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
