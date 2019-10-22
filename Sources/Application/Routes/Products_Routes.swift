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
    var id : String
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
        router.delete("/\(collectionName)/:id", handler: delete)
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
            try response.send([ "Values" : items.compactMap{$0}]).end()
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
            // Find item in database
            let item = try collection.find(["id" : id])
            
            response.headers.setType("json")
            let items = item.compactMap{$0}
            if (!items.isEmpty) {try response.send(items[0]).end()}
            else { try response.status(.badRequest).end() }
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
        
        let product = try! JSONDecoder().decode(Product.self, from: data)
        
        do {
            // Insert into database
            try collection.insertOne(product)
            
            // Send success response
            response.status(.created)
            try response.send([ "Added" : product ]).end()
            
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
        
        // edFixMe Update's not working
        let document = try Document.init(fromJSON: data)
        
        do {
            let result = try collection.updateMany(filter: ["id" : id], update: document)

            // Send appropriate result
            if result?.upsertedCount == 1 {
                try response.send([ "Updated" : document]).end()
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
            // Remove item from collection
            let result = try collection.deleteMany(["id" : id])
            // Send response
            try response.send(["Deleted" : result?.deletedCount]).end()
        } catch {
            response.status(.internalServerError)
            Log.error("Error: Unable to remove object from the database")
        }
    }

    // Helper method to convert json to MongoKitten Document
    fileprivate func convert(json: Data) -> Document? {
        guard let jsonStr = String(data: json, encoding: .utf8),
            let doc = try? Document(arrayLiteral: jsonStr) else {
                return nil
        }
        return doc
    }
}
