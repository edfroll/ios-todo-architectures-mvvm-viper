//
//  TaskMainProtocols.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation
import Combine

// MARK: - Presenter
protocol TaskMainPresenterProtocol: AnyObject {
    var displayTasks: [TaskDisplayModel] { get }
    var searchText: String { get set }
    
    func setupUpdateObserver()
    func viewDidLoad()
    func userDidSearch()
    func userDidTapAddTask()
    func userDidTapReset()
    func userDidTapToggleCompletion(for id: UUID)
    func userDidTapDelete(for id: UUID)
    func userDidTapEdit(for id: UUID)
    func taskCountText(for count: Int) -> String
    func didFetchTasks(_ tasks: [DataTask])
}
// MARK: - Interactor
protocol TaskMainInteractorProtocol: AnyObject {
    var presenter: TaskMainPresenterProtocol? { get set }
    var reloadCompleted: PassthroughSubject<Void, Never> { get }
    
    func fetchTasks()
    func loadInitialDataIfNeeded()
    func createNewTask() -> UUID
    func toggleTaskCompletion(at id: UUID)
    func deleteTask(at id: UUID)
    func resetAndReload()
}
// MARK: - Router
protocol TaskMainRouterProtocol: AnyObject {
    var path: [UUID] { get set }
    
    func showTaskDetail(for id: UUID)
}

