//
//  Grades.swift
//  Application
//
//  Created by sagar kothari on 23/08/19.
//

import SwiftKuery

class Grades: Table {
	let tableName = "Grades"
	let id = Column("id", Int32.self, primaryKey: true)
	let course = Column("course", String.self)
	let grade = Column("grade", Int32.self)
}

struct Grade: Codable {
	let id: Int
	let course: String
	let grade: Int
}
