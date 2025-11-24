//
//  TaskMainProtocols.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

// MARK: - Main Presenter Protocol
protocol TaskMainPresenterProtocol: AnyObject {
    var displayTasks: [TaskDisplayModel] { get }
    var searchText: String { get set }
    
    func setupUpdateObserver()
    func viewDidLoad()
    func userDidSearch(query: String)
    func userDidTapAddTask()
    func userDidTapReset()
    func userDidTapToggleCompletion(for id: UUID)
    func userDidTapDelete(for id: UUID)
    func userDidTapEdit(for id: UUID)
    func taskCountText(for count: Int) -> String
    func didFetchTasks(_ tasks: [DataTask])
}
// MARK: - Main Interactor Protocol
protocol TaskMainInteractorProtocol: AnyObject {
    var presenter: TaskMainPresenterProtocol? { get set }
    
    func fetchTasks()
    func loadInitialDataIfNeeded()
    func createNewTask() -> UUID
    func toggleTaskCompletion(at id: UUID)
    func deleteTask(at id: UUID)
    func resetAndReload()
}
// MARK: - Main Router Protocol
protocol TaskMainRouterProtocol: AnyObject {
    var path: [UUID] { get set }
    
    func showTaskDetail(for id: UUID)
}

