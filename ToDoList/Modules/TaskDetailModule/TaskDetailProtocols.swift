//
//  TaskDetailProtocols.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

// MARK: - Presenter
protocol TaskDetailPresenterProtocol: AnyObject {
    func viewDidLoad()
    func userDidTapBack()
    
    func didFetchTask(_ task: DataTask)
    func didChangeTask()
}
// MARK: - Interactor
protocol TaskDetailInteractorProtocol: AnyObject {
    var presenter: TaskDetailPresenterProtocol? { get set }
    
    func fetchTask()
    func updateTask(_ newTitle: String?, _ newBody: String?)
    func deleteTask()
}
// MARK: - Router
protocol TaskDetailRouterProtocol: AnyObject {
    static func createModule(taskId: UUID) -> TaskDetailView
}
