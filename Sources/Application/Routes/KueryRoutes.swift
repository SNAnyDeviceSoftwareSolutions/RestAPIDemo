import LoggerAPI
import Health
import KituraContracts
import SwiftKuery
import SwiftKueryPostgreSQL

func initializeKueryRoutes(app: App) {
	app.router.post("/grades", handler: app.insertHandler)
	app.router.get("/grades", handler: app.selectHandler)
}

extension App {
	static let poolOptions = ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50)
	static let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("restapidemo")], poolOptions: poolOptions)
	static let gradesTable = Grades()

	func insertHandler(grade: Grade, completion: @escaping (Grade?, RequestError?) -> Void) {
		let rows = [[grade.id, grade.course, grade.grade]]
		App.pool.getConnection() { connection, error in
			guard let connection = connection else {
				Log.error("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
				return completion(nil, .internalServerError)
			}
			let insertQ = Insert(into: App.gradesTable, rows: rows)
			connection.execute(query: insertQ) { insertResult in
				guard insertResult.success else {
					Log.error("Error executing query: \(insertResult.asError?.localizedDescription ?? "Unknown Error")")
					return completion(nil, .internalServerError)
				}
				completion(grade, nil)
			}
		}
	}

	func selectHandler(completion: @escaping ([Grade]?, RequestError?) -> Void) {
		App.pool.getConnection() { connection, error in
			guard let connection = connection else {
				Log.error("Error connecting: \(error?.localizedDescription ?? "Unknown Error")")
				return completion(nil, .internalServerError)
			}
			let selectQuery = Select(from: App.gradesTable)
			connection.execute(query: selectQuery) { selectResult in
				self.handle(query: selectResult, completion: completion)
			}
		}
	}
}

// Select Grades handlers
extension App {
	private func returnGrades(
		using resultSet: ResultSet,
		completion: @escaping ([Grade]?, RequestError?) -> Void) {
		var grades = [Grade]()
		resultSet.forEach() { row, error in
			guard let row = row else {
				if let error = error {
					Log.error("Error getting grade row: \(error.localizedDescription)")
					completion(nil, .internalServerError); return
				} else {
					return completion(grades, nil)
				}
			}
			guard
				let idString = row[0] as? String,
				let id = Int(idString),
				let course = row[1] as? String,
				let grade = row[2] as? Int32
				else {
					Log.error("Unable to decode book")
					completion(nil, .internalServerError); return
			}
			grades.append(Grade(id: id, course: course, grade: Int(grade)))
		}
	}

	private func handle(
		query result: QueryResult,
		completion: @escaping ([Grade]?, RequestError?) -> Void) {
		switch result {
			case .resultSet(let resultSet):
				self.returnGrades(using: resultSet, completion: completion)
			case .successNoData:
				return completion([], nil)
			case .error(let error):
				Log.error("Error fetching grades error: \(error.localizedDescription)")
				return completion(nil, .internalServerError)
			case .success:
				Log.error("Success but something went wrong")
				return completion(nil, .internalServerError)
		}
	}
}
