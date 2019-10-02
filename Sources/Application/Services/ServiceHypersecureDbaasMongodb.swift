import LoggerAPI
import CloudEnvironment
import MongoKitten

func initializeServiceHypersecureDbaasMongodb(cloudEnv: CloudEnv) throws -> MongoDatabase {
    guard let mongodbCredentials = cloudEnv.getHyperSecureDBaaSCredentials(name: "hypersecure_dbaas_mongodb") else {
        throw InitializationError("Could not load credentials for HyperSecure MongoDB.")
    }

    // Add SSL Certificate parameters
    let mongodbUri = mongodbCredentials.uri.components(separatedBy: "?")[0]
    let mongodbSsl = mongodbUri + "?ssl=true&ssl_ca_certs=/Sources/Application/Services/cert.pem"

    let mongodb = try MongoDatabase.synchronousConnect(mongodbSsl)
    Log.info("Found and loaded credentials for HyperSecure MongoDB.")
    return mongodb
}
