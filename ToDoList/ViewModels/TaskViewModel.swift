//
//  TaskViewModel.swift
//  ToDoList
//
//  Created by Эдвард on 18.09.2025.
//
import SwiftUI
import CoreData

@MainActor
class TaskViewModel: ObservableObject {
    
    let container: NSPersistentContainer
    private let jsonVM: JsonViewModel = JsonViewModel()
    
    @Published var tasks: [TaskDisplayModel] = []
    @Published var searchText: String = ""
    
    // MARK: - Init
    init() {
        container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Ошибка загрузки CoreData: \(error.localizedDescription)")
                return  // ✅ Важно вернуться при ошибке
            }
            // ✅ Вызываем только после успешной загрузки
            self.fetchData()
            self.loadInitialDataIfNeeded()
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func loadInitialDataIfNeeded() {
        let hasLoaded = UserDefaults.standard.bool(forKey: "hasLoadedInitialData")
        
        if !hasLoaded && tasks.isEmpty {
            loadTasksFromApi()
            UserDefaults.standard.set(true, forKey: "hasLoadedInitialData")
        }
    }
    
    // MARK: - Network
    func loadTasksFromApi() {
        Task {
            do {
                let apiTasks = try await jsonVM.fetchTasks()
                
                try await saveApiTasks(apiTasks)
                
                await MainActor.run {
                    self.fetchData()
                }
                
            } catch {
                print("Ошибка загрузки данных из API: \(error)")
            }
        }
    }
    
    private func saveApiTasks(_ apiTasks: [ApiModel]) async throws {
        try await bgContext.perform {
            for api in apiTasks {
                let task = DataTask(context: self.bgContext)
                task.id = UUID()
                task.title = String(api.id)
                task.body = api.todo
                task.date = .now
                task.isCompleted = api.completed
            }
            try self.bgContext.save()
        }
    }
    
    // MARK: - Create
    func createNewTask() -> UUID {
        let newTask = DataTask(context: container.viewContext)
        newTask.id = UUID()
        newTask.title = ""
        newTask.body = ""
        newTask.date = Date.now
        newTask.isCompleted = false
        
        saveContext()
        fetchData()
        
        return newTask.id ?? { fatalError("ID must exist") }()
    }
    
    // MARK: - Read
    func fetchData() {
        do {
            let fetchedTasks = try container.viewContext.fetch(fetchRequest)
            tasks = fetchedTasks.compactMap { dataTask -> TaskDisplayModel? in
                guard let id = dataTask.id,
                      let date = dataTask.date else {
                    return nil
                }
                return TaskDisplayModel(
                    id: id,
                    title: dataTask.title ?? "",
                    body: dataTask.body ?? "",
                    dateString: formatter.string(from: date),
                    isCompleted: dataTask.isCompleted
                )
            }
        } catch {
            print("Ошибка загрузки данных: \(error.localizedDescription)")
        }
    }
    // MARK: - Update
    func updateTask(id: UUID, newTitle: String, newBody: String) {
        guard !newTitle.isEmpty || !newBody.isEmpty else {
            return deleteTask(at: id)
        }
        
        guard let task = findTask(by: id) else { return }
        
        var didChange = false
        
        if task.title != newTitle {
            task.title = newTitle
            didChange = true
        }
        if task.body != newBody {
            task.body = newBody
            didChange = true
        }
        
        if didChange {
            task.date = Date.now
            saveContext()
            fetchData()
        }
    }
    
    func toggleTaskCompletion(at id: UUID) {
        guard let task = findTask(by: id) else { return }
        task.isCompleted.toggle()
        saveContext()
        fetchData()
    }
    
    // MARK: - Delete
    func deleteTask(at id: UUID) {
        guard let task = findTask(by: id) else { return }
        container.viewContext.delete(task)
        saveContext()
        fetchData()
    }

    // MARK: - Reset and Reload
    func resetAndReload() {
        Task {
            do {
                try await bgContext.perform {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DataTask")
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    deleteRequest.resultType = .resultTypeObjectIDs
                    
                    let result = try self.bgContext.execute(deleteRequest) as? NSBatchDeleteResult
                    let objectIDs = result?.result as? [NSManagedObjectID] ?? []
                    
                    let changes = [NSDeletedObjectsKey: objectIDs]
                    
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: changes,
                        into: [self.container.viewContext]
                    )
                }
                // Реинициализация загрузки
                UserDefaults.standard.removeObject(forKey: "hasLoadedInitialData")
                
                await MainActor.run {
                    self.tasks = []
                }
                
                loadTasksFromApi()
            } catch {
                print("Ошибка сброса данных")
            }
        }
    }
    
    // MARK: - Helpers
    private func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Ошибка сохранения \(error.localizedDescription)")
            }
        }
    }
    
    private lazy var bgContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    private lazy var fetchRequest = {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DataTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \DataTask.date, ascending: false)
        ]
        return request
    }()
    
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yy"
        return df
    }()


    private func findTask(by id: UUID) -> DataTask? {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? container.viewContext.fetch(request).first
    }

 
    
    var filteredTasks: [TaskDisplayModel] {
        if searchText.isEmpty {
            return tasks
        } else {
            return tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.body.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func taskCountText(for count: Int) -> String {
        let remainder10 = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 14 {
            return "\(count) задач"
        }
        switch remainder10 {
        case 1:
            return "\(count) задача"
        case 2...4:
            return "\(count) задачи"
        default:
            return "\(count) задач"
        }
    }
}
