import Kitura
import KituraNet
import KituraContracts
import MongoSwift
import LoggerAPI
import Foundation

func initializeProducts_Routes(app: App) {
    let collectionName = "products"
    let databaseName = "productsDB"
    let controller = MongoController(app: app, collectionName: collectionName, databaseName : databaseName)
    controller.registerRoutes()
}

/// A Codable type that matches the data in our Products in routes
private struct Product: Codable {
    var name: String
    var description: String
}

class MongoController {
    
    // The application router
    fileprivate let router: Router
    
    // The DB name (here, productsDB)
    fileprivate let databaseName : String
    
    // The mongo database
    fileprivate let database: SyncMongoDatabase
    
    
    // The name of the database collection
    fileprivate let collectionName: String
    
    // Mongo collection
    fileprivate var collection: SyncMongoCollection<Product> {
        return database.collection(collectionName, withType: Product.self)
    }
    
    // Initializer
    public init(app: App, collectionName: String, databaseName : String) {
        self.router = app.router
        self.collectionName = collectionName
        self.databaseName = databaseName
        self.database =  app.services.mongoDBClientService.db(databaseName)
        
        // Create the collection if necessary
        do {
            let _ = try database.listCollectionNames().contains(collectionName) ? database.collection(collectionName) : database.createCollection(collectionName)
        } catch {
            Log.error("Error: Unable to add or access collection")
        }
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
            let items = try collection.find()
            
            // Send success response
            response.headers.setType("json")
            try response.send(Array(items)).end()
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
            let _id = ObjectId(id)!
            
            // Find item in database
            let item = try collection.find(["_id": _id])

//            else {
//                    response.status(.internalServerError)
//                    Log.error("Error: Object doesn't exist")
//            }

            response.headers.setType("json")
            try response.send(Array(item)).end()
            
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

        // Convert json data to Mongo Swift Document
        guard let document = convert(json: data) else {
            try response.status(.badRequest).end()
            Log.error("Body contains invalid JSON")
            return
        }
        
        do {
            // Insert into database
            try collection.insertOne(Product.init(name: document.keys[0] , description: document.values[0] as! String))
 
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
            let _id = ObjectId(id)!
            // Update Document with ID
            let result = try collection.updateOne(filter: ["_id" == _id.hex], update: document)
            // Send appropriate result
            if result?.upsertedCount == 1 {
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
    
    // Handler to delete the specified entry in the database. Exists gracefully even if the entry doesn't exist
    fileprivate func delete(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        
        // Retrieve ID route parameter
        guard let id = request.parameters["id"] else {
            try response.status(.badRequest).end()
            Log.error("Expected parameter: `id`")
            return
        }
        
        do {
            // Create MongoKitten ID
            // _id = ObjectId(id)!
            // Remove item from collection
            let result = try collection.deleteOne(["_id" == id])
            // Create response code
            let status: HTTPStatusCode = result == nil ? .OK : .notFound
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
