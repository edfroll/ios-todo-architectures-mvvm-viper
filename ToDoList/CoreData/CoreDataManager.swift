//
//  CoreDataManager.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Ошибка загрузки CoreData: \(error.localizedDescription)")
            } else {
                print("✅ Core Data успешно загружена")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Контекст сохранен")
            } catch {
                print("❌ Ошибка сохранения контекста")
            }
        }
    }
}
