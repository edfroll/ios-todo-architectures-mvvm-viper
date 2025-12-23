//
//  ToDoListTests.swift
//  ToDoListTests
//
//  Created by Эдвард on 24.11.2025.
//
import XCTest
import CoreData
@testable import ToDoList

final class TaskMainInteractorTests: XCTestCase {
    
    var sut: TaskMainInteractor!
    var mockPresenter: MockTaskMainPresenter!
    var testManager: CoreDataManager!
    
    override func setUp() {
        super.setUp()
        
        testManager = CoreDataManager.createInMemory()
        
        mockPresenter = MockTaskMainPresenter()

        sut = TaskMainInteractor(container: testManager.container, jsonService: JsonService())
        sut.presenter = mockPresenter
    }
    
    override func tearDown() {
        sut = nil
        mockPresenter = nil
        testManager = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    private func createTestTask(title: String, body: String, isCompleted: Bool = false) -> UUID {
        let task = DataTask(context: testManager.container.viewContext)
        let id = UUID()
        task.id = id
        task.title = title
        task.body = body
        task.date = Date()
        task.isCompleted = isCompleted
        
        try? testManager.container.viewContext.save()
        return id
    }
    
    // MARK: - Tests: Fetch
    func testFetchTask_EmptyDatabase_ReturnsEmptyArray() {
        // Given: пустая база данных
        
        // When:
        sut.fetchTasks()
        
        // Then:
        let expectation = XCTestExpectation(description: "Presenter called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockPresenter.didFetchTasksCalled)
            XCTAssertEqual(self.mockPresenter.fetchedTasks.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchTasks_WithData_ReturnsAllTasks() {
        // Given: Создаем тестовые задачи
        _ = createTestTask(title: "Title 1", body: "Body 1")
        _ = createTestTask(title: "Title 2", body: "Body 2")
        _ = createTestTask(title: "Title 3", body: "Body 3")
        
        // When:
        sut.fetchTasks()
        
        // Then:
        let expectation = XCTestExpectation(description: "Presenter called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockPresenter.didFetchTasksCalled)
            XCTAssertEqual(self.mockPresenter.fetchedTasks.count, 3)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchTasks_SortsCorrectly() {
        // Given: Задачи с разным статусом
        _ = createTestTask(title: "Completed", body: "Body", isCompleted: true)
        _ = createTestTask(title: "Active", body: "Body", isCompleted: false)
        
        // When:
        sut.fetchTasks()
        
        // Then:
        let expectation = XCTestExpectation(description: "Sorted correctly")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let tasks = self.mockPresenter.fetchedTasks
            XCTAssertEqual(tasks.count, 2)
            // Активные должны быть первыми (isCompleted: false)
            XCTAssertFalse(tasks[0].isCompleted)
            XCTAssertTrue(tasks[1].isCompleted)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test: Create
    func testCreateNewTask_ReturnsValidUUID() {
        // When:
        let id = sut.createNewTask()
        
        XCTAssertNotNil(id)
        XCTAssertNotEqual(id, UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    func testCreateNewTask_CreatesTaskWithEmptyFields() {
        // When
        let id = sut.createNewTask()
        
        
        // Then: Проверяем что задача создана с пустыми полями
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let tasks = try? testManager.container.viewContext.fetch(request)
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.title, "")
        XCTAssertEqual(tasks?.first?.body, "")
        XCTAssertFalse(tasks?.first?.isCompleted ?? true)
    }
    
    // MARK: - Tests: Toggle Completion
    func testToggleTaskCompletion_ChangesStatus() {
        // Given
        let id = createTestTask(title: "Test", body: "Body", isCompleted: false)
        sut.fetchTasks()
        
        // Wait for fetch
        let fetchExpectation = XCTestExpectation(description: "Fetch Complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        sut.toggleTaskCompletion(at: id)
        
        // Then
        let expectation = XCTestExpectation(description: "Status toggled:")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let tasks = self.mockPresenter.fetchedTasks
            let task = tasks.first(where: { $0.id == id })
            XCTAssertTrue(task?.isCompleted ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Tests: Delete
    func testDeleteTask_RemovesTaskFromDatabase() {
        // Given
        let id = createTestTask(title: "To delete", body: "Body")
        sut.fetchTasks()
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        sut.deleteTask(at: id)
        
        // Then
        let expectation = XCTestExpectation(description: "Task deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let tasks = self.mockPresenter.fetchedTasks
            XCTAssertEqual(tasks.count, 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
}

// MARK: - Mock Presenter
class MockTaskMainPresenter: TaskMainPresenterProtocol {
    var displayTasks: [TaskDisplayModel] = []
    var searchText: String = ""
    
    var didFetchTasksCalled = false
    var fetchedTasks: [DataTask] = []
    
    func setupUpdateObserver() {}
    func viewDidLoad() {}
    func userDidSearch() {}
    func userDidTapAddTask() {}
    func userDidTapReset() {}
    func userDidTapToggleCompletion(for id: UUID) {}
    func userDidTapDelete(for id: UUID) {}
    func userDidTapEdit(for id: UUID) {}
    func taskCountText(for count: Int) -> String { return "" }
    
    func didFetchTasks(_ tasks: [DataTask]) {
        didFetchTasksCalled = true
        fetchedTasks = tasks
    }
    
    
}
