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
    
    //Для тестов
    static func createInMemory() -> CoreDataManager {
        let manager = CoreDataManager(inMemory: true)
        return manager
    }
    
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            // ✅ Используем in-memory store description для тестов
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Ошибка загрузки CoreData: \(error.localizedDescription)")
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
            } catch {
                print("❌ Ошибка сохранения контекста")
            }
        }
    }
}
