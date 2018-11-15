import Kitura
import KituraNet
import KituraContracts
import MongoKitten
import LoggerAPI
import Foundation

func initializeAppRoutes(app: App) {
    let collectionName = "products"
    let controller = SupplementalMongoController(app: app, collectionName: collectionName)
    controller.registerRoutes()
}

class SupplementalMongoController {

    // The application router
    fileprivate let router: Router

    // The mongo database
    fileprivate let database: Database

    // The name of the database collection
    fileprivate let collectionName: String

    // Mongo collection
    fileprivate var collection: MongoCollection {
        return database[collectionName]
    }

    // Initializer
    public init(app: App, collectionName: String) {
        self.router = app.router
        self.collectionName = collectionName
        self.database =  app.services.mongoDBService

        // Create the collection if necessary
        let _ = try? database.createCollection(named: collectionName)
    }

    // Method to register routes
    public func registerRoutes() {
        router.patch("/\(collectionName)/:id", handler: update)
        router.delete("/\(collectionName)", handler: deleteAll)
    }
}

/// Extension containing route handlers
extension SupplementalMongoController {
    // Handler to update the specified entry in the database
    fileprivate func update(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        // Retrieve ID route parameter
        guard let id = request.parameters["id"] else {
            try response.status(.badRequest).end()
            Log.error("Expected parameter: `id`")
            return
        }

        // Read in the request body
        var data = Data()
        guard let _ = try? request.read(into: &data) else {
            try response.status(.badRequest).end()
            Log.error("No body found in request")
            return
        }

        // Convert json data to MongoKitten Document
        guard let document = convert(json: data) else {
            try response.status(.badRequest).end()
            Log.error("Body contains invalid JSON")
            return
        }

        do {
            // Create MongoKitten ID
            let _id = try ObjectId(id)
            // Update Document with ID
            let result = try collection.update("_id" == _id, to: document)
            // Send appropriate result
            if result == 1 {
                try response.send(json: document).end()
            } else {
                try response.status(.notFound).end()
            }

        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to update object in the database")
        }
    }

    /*// Handler to delete the specified entry in the database
    fileprivate func delete(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {

        // Retrieve ID route parameter
        guard let id = request.parameters["id"] else {
            try response.status(.badRequest).end()
            Log.error("Expected parameter: `id`")
            return
        }

        do {
            // Create MongoKitten ID
            let _id = try ObjectId(id)
            // Remove item from collection
            let result = try collection.remove("_id" == _id, limitedTo: 1)
            // Create response code
            let status: HTTPStatusCode = result == 1 ? .OK : .notFound
            // Send response
            try response.send(status: status).end()
        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to remove object from the database")
        }
    }*/

    // Handler to delete all entries in the database
    fileprivate func deleteAll(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        do {
            // Remove all items from the collection
            try collection.remove()
            // Send success response
            try response.status(.OK).end()
        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to remove objects from the database")
        }
    }

    // Helper method to convert json to MongoKitten Document
    fileprivate func convert(json: Data) -> Document? {
        guard let jsonStr = String(data: json, encoding: .utf8),
              let doc = try? Document(extendedJSON: jsonStr) else {
            return nil
        }
        return doc
    }
}
