import LoggerAPI
import CloudEnvironment
import MongoSwift
import Foundation

func initializeServiceHypersecureDbaasMongodb(cloudEnv: CloudEnv) throws -> SyncMongoClient {
    guard let mongodbCredentials = cloudEnv.getHyperSecureDBaaSCredentials(name: "hypersecure_dbaas_mongodb") else {
        throw InitializationError("Could not load credentials for HyperProtect MongoDB.")
    }

    // Add SSL Certificate parameters
    let mongodbUri = mongodbCredentials.uri.components(separatedBy: "?")[0]

    let sslOpts = TLSOptions(allowInvalidHostnames: true, caFile: URL(string: "/Users/edesouza/Projects/swift-dbaas-test/kitura-dbaas/Sources/cert.pem"), pemFile: nil)

    let mongodb = try  SyncMongoClient("mongodb://admin:Eiu1h1ao1919988@dbaas30.hyperp-dbaas.cloud.ibm.com:28020,dbaas31.hyperp-dbaas.cloud.ibm.com:28105,dbaas29.hyperp-dbaas.cloud.ibm.com:28090/admin", options: ClientOptions(serverMonitoring: true, tlsOptions: sslOpts))
    Log.info("Found and loaded credentials for HyperProtect MongoDB.")
    return mongodb
}
