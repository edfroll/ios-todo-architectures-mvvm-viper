//
//  TaskDetailProtocols.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import Foundation

// MARK: - Detail Presenter Protocol
protocol TaskDetailPresenterProtocol: AnyObject {
    func viewDidLoad()
    func userDidTapBack()
    
    func didFetchTask(_ task: DataTask)
    func didChangeTask()
}
// MARK: - Detail Interactor Protocol
protocol TaskDetailInteractorProtocol: AnyObject {
    var presenter: TaskDetailPresenterProtocol? { get set }
    
    func fetchTask()
    func updateTask(_ newTitle: String?, _ newBody: String?)
    func deleteTask()
}
// MARK: - Router Protocol
protocol TaskDetailRouterProtocol: AnyObject {
    static func createModule(taskId: UUID) -> TaskDetailView
}
