//
//  TaskMainPresenterTests.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import XCTest
import CoreData
import Combine

@testable import ToDoList

final class TaskMainPresenterTests: XCTestCase {
    
    var sut: TaskMainPresenter!
    var mockInteractor: MockTaskMainInteractor!
    var mockRouter: MockTaskMainRouter!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockInteractor = MockTaskMainInteractor()
        mockRouter = MockTaskMainRouter()
        sut = TaskMainPresenter(interactor: mockInteractor, router: mockRouter)
    }
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        mockRouter = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Tests: View Did Load
    func testViewDidLoad_CallsFetchTasksAndLoadInitialData() {
        // When
        sut.viewDidLoad()
        
        // Then
        XCTAssertTrue(mockInteractor.fetchTasksCalled)
        XCTAssertTrue(mockInteractor.loadInitialDataCalled)
    }
    
    func testUserDidSearch_FiltersTasksByTitle() {
        // Given
        let task1 = createMockDataTask(id: UUID(), title: "Buy milk", body: "From store")
        let task2 = createMockDataTask(id: UUID(), title: "Call mom", body: "About birthday")
        sut.didFetchTasks([task1, task2])
        
        // When
        sut.searchText = "milk"
        sut.userDidSearch()
        
        // Then
        let expectation = XCTestExpectation(description: "Tasks filtered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.displayTasks.count, 1)
            XCTAssertEqual(self.sut.displayTasks.first?.title, "Buy milk")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testUserDidSearch_FiltersTasksByBody() {
        // Given
        let task1 = createMockDataTask(id: UUID(), title: "Shopping", body: "Buy milk")
        let task2 = createMockDataTask(id: UUID(), title: "Call", body: "Mom")
        sut.didFetchTasks([task1, task2])
        
        // When
        sut.searchText = "milk"
        sut.userDidSearch()
        
        // Then
        let expectation = XCTestExpectation(description: "Tasks filtered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.displayTasks.count, 1)
            XCTAssertEqual(self.sut.displayTasks.first?.body, "Buy milk")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUserDidSearch_EmptyQuery_ShowAllTasks() {
        // Given
        let task1 = createMockDataTask(id: UUID(), title: "Task 1", body: "Body: 1")
        let task2 = createMockDataTask(id: UUID(), title: "Task 2", body: "Body: 2")
        sut.didFetchTasks([task1, task2])
        
        // When
        sut.searchText = ""
        sut.userDidSearch()
        
        // Then
        let expectation = XCTestExpectation(description: "All tasks shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.displayTasks.count, 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Tests: User Actions
    func testUserDidTapAddTask_CallsInteractorAndRouter() {
        // Given
        let expectedId = UUID()
        mockInteractor.mockNewTaskId = expectedId
        
        // When
        sut.userDidTapAddTask()
        
        // Then
        XCTAssertTrue(mockInteractor.createNewTaskCalled)
        XCTAssertTrue(mockRouter.showTaskDetailCalled)
        XCTAssertEqual(mockRouter.showTaskDetailId, expectedId)
    }
    
    func testUserDidTapToggleCompletion_CallsInteractor() {
        // Given
        let taskId = UUID()
        
        // When
        sut.userDidTapToggleCompletion(for: taskId)
        
        // Then
        XCTAssertTrue(mockInteractor.toggleCompletionCalled)
        XCTAssertEqual(mockInteractor.toggleCompletionId, taskId)
    }
    
    func testUserDidTapDelete_CallsInteractor() {
        // Given
        let taskId = UUID()
        
        // When
        sut.userDidTapDelete(for: taskId)
        
        // Then
        XCTAssertTrue(mockInteractor.deleteTaskCalled)
        XCTAssertEqual(mockInteractor.deleteTaskId, taskId)
    }
    
    func testUserDidTapEdit_CallsRouter() {
        // Given
        let taskId = UUID()
        
        // When
        sut.userDidTapEdit(for: taskId)
        
        // Then
        XCTAssertTrue(mockRouter.showTaskDetailCalled)
        XCTAssertEqual(mockRouter.showTaskDetailId, taskId)
    }
    
    func testUserDidTapReset_CallsInteractor() {
        // When
        sut.userDidTapReset()
        
        // Then
        XCTAssertTrue(mockInteractor.resetAndReloadCalled)
    }
    
    // MARK: - Tests: Task Count Text
    func testTaskCountText_1Task_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 1), "1 задача")
    }
    
    func testTaskCountText_2Tasks_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 2), "2 задачи")
    }
    
    func testTaskCountText_5Tasks_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 5), "5 задач")
    }
    
    func testTaskCountText_11Tasks_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 11), "11 задач")
    }
    
    func testTaskCountText_21Tasks_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 21), "21 задача")
    }
    
    func testTaskCountText_22Tasks_ReturnsCorrectForm() {
        XCTAssertEqual(sut.taskCountText(for: 22), "22 задачи")
    }
    
    // MARK: - Tests: Display Tasks Conversion
    func testDidFetchTask_ConvertsToDisplayModels() {
        // Given
        let task = createMockDataTask(
            id: UUID(),
            title: "Test Title",
            body: "Test Body",
            isCompleted: true
        )
        
        // When
        sut.didFetchTasks([task])
        
        // Then
        let expectation = XCTestExpectation(description: "Converted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.sut.displayTasks.count, 1)
            let displayTask = self.sut.displayTasks.first!
            XCTAssertEqual(displayTask.title, "Test Title")
            XCTAssertEqual(displayTask.body, "Test Body")
            XCTAssertTrue(displayTask.isCompleted)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper
    private func createMockDataTask(id: UUID, title: String, body: String, isCompleted: Bool = false) -> DataTask {
        let context = MockCoreDataStack.shared.context
        let task = DataTask(context: context)
        task.id = id
        task.title = title
        task.body = body
        task.date = Date()
        task.isCompleted = isCompleted
        return task
        
    }
}

// MARK: - Mock Interactor
class MockTaskMainInteractor: TaskMainInteractorProtocol {
    var reloadCompleted = PassthroughSubject<Void, Never>()
    var presenter: TaskMainPresenterProtocol?
    
    var fetchTasksCalled = false
    var loadInitialDataCalled = false
    var createNewTaskCalled = false
    var toggleCompletionCalled = false
    var deleteTaskCalled = false
    var resetAndReloadCalled = false
    
    var mockNewTaskId = UUID()
    var toggleCompletionId: UUID?
    var deleteTaskId: UUID?
    
    func fetchTasks() {
        fetchTasksCalled = true
    }
    func loadInitialDataIfNeeded() {
        loadInitialDataCalled = true
    }
    func createNewTask() -> UUID {
        createNewTaskCalled = true
        return mockNewTaskId
    }
    func toggleTaskCompletion(at id: UUID) {
        toggleCompletionCalled = true
        toggleCompletionId = id
    }
    func deleteTask(at id: UUID) {
        deleteTaskCalled = true
        deleteTaskId = id
    }
    func resetAndReload() {
        resetAndReloadCalled = true
    }
}

// MARK: - Mock Router
class MockTaskMainRouter: TaskMainRouterProtocol {
    
    var path: [UUID] = []
    
    var showTaskDetailCalled = false
    var showTaskDetailId: UUID?
    
    func showTaskDetail(for id: UUID) {
        showTaskDetailCalled = true
        showTaskDetailId = id
    }
}

// MARK: - Mock Core Data Stack
class MockCoreDataStack {
    static let shared = MockCoreDataStack()
    
    let context: NSManagedObjectContext
    
    private init() {
        let container = NSPersistentContainer(name: "DataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, _ in }
        context = container.viewContext
    }
}



