import LoggerAPI
import CloudEnvironment
import MongoSwift
import Foundation

func initializeServiceHypersecureDbaasMongodb(cloudEnv: CloudEnv) throws -> SyncMongoClient {
    guard let mongodbCredentials = cloudEnv.getHyperSecureDBaaSCredentials(name: "hyperprotect_dbaas_mongodb") else {
        throw InitializationError("Could not load credentials for HyperProtect MongoDB.")
    }

    let sslOpts = TLSOptions(allowInvalidHostnames: true, caFile: URL(string: mongodbCredentials.cert), pemFile: nil)

    let mongodb = try  SyncMongoClient(String("mongodb://\(mongodbCredentials.username):\(mongodbCredentials.password)@\(mongodbCredentials.uri)/\(mongodbCredentials.db)"),options: ClientOptions(serverMonitoring: true, tlsOptions: sslOpts))
    Log.info("Found and loaded credentials for HyperProtect MongoDB.")
    return mongodb
}
