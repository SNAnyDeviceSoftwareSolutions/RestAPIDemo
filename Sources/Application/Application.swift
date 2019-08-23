import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraOpenAPI
import SwiftKuery
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
	let router = Router()
	let cloudEnv = CloudEnv()
	var pool: ConnectionPool?
	let dbConError = RequestError(rawValue: 522, reason: "Couldn't connect to db")
	// let students: [[Any]] = [[0, "computing", 92], [1, "physics", 75], [2, "history", 83]]

	public init() throws {
		// Run the metrics initializer
		initializeMetrics(router: router)
	}

	func postInit() throws {
		// Endpoints
		initializeHealthRoutes(app: self)
		initializeKueryRoutes(app: self)
		KituraOpenAPI.addEndpoints(to: router)
	}

	public func run() throws {
		try postInit()
		Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
		Kitura.run()
	}
}
