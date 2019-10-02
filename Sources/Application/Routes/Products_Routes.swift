import Kitura
import KituraNet
import KituraContracts
import MongoKitten
import LoggerAPI
import Foundation

func initializeProducts_Routes(app: App) {
    let collectionName = "products"
    let controller = MongoController(app: app, collectionName: collectionName)
    controller.registerRoutes()
}

class MongoController {

    // The application router
    fileprivate let router: Router

    // The mongo database
    fileprivate let database: MongoDatabase

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
        let _ = database[collectionName]
    }

    // Method to register routes
    public func registerRoutes() {
        router.get("/\(collectionName)/:id", handler: get)
        router.get("/\(collectionName)", handler: getAll)
        router.post("/\(collectionName)", handler: create)
        router.put("/\(collectionName)/:id", handler: update)
        //router.patch("/\(collectionName)/:id", handler: update)
        router.delete("/\(collectionName)/:id", handler: delete)
        //router.delete("/\(collectionName)", handler: deleteAll)
    }
}

/// Extension containing route handlers
extension MongoController {

    // Handler to retrieve all entries in the database
    fileprivate func getAll(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        do {
            // Finds the items in the collection and convert it to a json object
            let items = try collection.find().allResults().wait()
                
                //.makeDocument()
                //.makeExtendedJSONString()

            // edFixMe : this returns bson but incorrectly marked as json, find BSON -> JSON for bson 7.0
            // Send success response
            response.headers.setType("json")
            try response.send(items).end()
        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to retrieve objects from the database")
        }
    }

    // Handler to retrieve the specified entry in the database
    fileprivate func get(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        // Retrieve ID route paramter
        guard let id = request.parameters["id"] else {
            try response.status(.badRequest).end()
            return
        }

        do {
            // Create MongoKitten ID
            let _id = ObjectId(id)

            // Find item in database
            guard let item = try collection.findOne("_id" == _id).wait()
            else {
                try response.send(status: .notFound).end()
                return
            }
            // Send success response
                // edFixMe : figure out BSON to JSON conversion in BSON 7
                response.headers.setType("json")
                try response.send(item).end()

            //            makeExtendedJSONString() else {
//                try response.send(status: .notFound).end()
//                return
//            }

        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to retrieve object from the database")
        }
    }

    // Handler to insert the specified entry in the database
    fileprivate func create(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
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
            // Insert into database
            collection.insert(document)

            // Send success response
            response.status(.created)
            try response.send(json: document).end()

        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to insert object into database")
        }
    }

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
            let _id = ObjectId(id)
            // Update Document with ID
            let result = try collection.updateOne(where: "_id" == _id, to: document).wait()
            // Send appropriate result
            if result.updatedCount == 1 {
                try response.send(json: document).end()
            } else {
                try response.status(.notFound).end()
            }
            try response.status(.notFound).end()

        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to update object in the database")
        }
    }

    // Handler to delete the specified entry in the database
    fileprivate func delete(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {

        // Retrieve ID route parameter
        guard let id = request.parameters["id"] else {
            try response.status(.badRequest).end()
            Log.error("Expected parameter: `id`")
            return
        }

        do {
            // Create MongoKitten ID
            let _id = ObjectId(id)
            // Remove item from collection
            let result = try collection.deleteOne(where: "_id" == _id).wait()
            // Create response code
            let status: HTTPStatusCode = result.ok > 0 ? .OK : .notFound
            // Send response
            try response.send(status: status).end()
        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to remove object from the database")
        }
    }

    /*// Handler to delete all entries in the database
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
    }*/

    // Helper method to convert json to MongoKitten Document
    fileprivate func convert(json: Data) -> Document? {
        guard let jsonStr = String(data: json, encoding: .utf8),
            let doc = try? Document(arrayLiteral: jsonStr) else {
            return nil
        }
        return doc
    }
}
