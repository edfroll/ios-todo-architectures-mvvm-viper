//
//  TaskDetailInteractorTests.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//
import XCTest
import CoreData

@testable import ToDoList

final class TaskDetailInteractorTests: XCTestCase {
    
    var sut: TaskDetailInteractor!
    var mockPresenter: MockTaskDetailPresenter!

    var testManager: CoreDataManager!
    var testTaskId: UUID!
    
    override func setUp() {
        super.setUp()

        testManager = CoreDataManager.createInMemory()
        mockPresenter = MockTaskDetailPresenter()
        
        // Создаем тестовую задачу
        testTaskId = createTestTask(title: "Test Task", body: "Test Body")
        sut = TaskDetailInteractor(taskId: testTaskId, container: testManager.container)
        sut.presenter = mockPresenter
    }
    
    override func tearDown() {
        sut = nil
        mockPresenter = nil
        testManager = nil
        testTaskId = nil
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods    
    private func createTestTask(title: String, body: String, isCompleted: Bool = false) -> UUID {
        let task = DataTask(context: testManager.container.viewContext)
        let id = UUID()
        task.id = id
        task.title = title
        task.body = body
        task.isCompleted = isCompleted
        
        try? testManager.container.viewContext.save()
        return id
    }
    
    private func getTaskFromDatabase(id: UUID) -> DataTask? {
        let request = NSFetchRequest<DataTask>(entityName: "DataTask")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? testManager.container.viewContext.fetch(request).first
    }
    
    // MARK: - Tests: Fetch Tasks
    func testFetchTask_ValidId_CallsPresenterWithTask() {
        // When
        sut.fetchTask()
        
        // Then
        let expectation = XCTestExpectation(description: "Presenter called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(self.mockPresenter.didFetchTaskCalled, "Presenter должен быть вызван")
            XCTAssertNotNil(self.mockPresenter.fetchedTask, "Задача должна быть передана")
            XCTAssertEqual(self.mockPresenter.fetchedTask?.title, "Test Task")
            XCTAssertEqual(self.mockPresenter.fetchedTask?.body, "Test Body")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchTask_InvalidId_DoesNotCallPresenter() {
        // Given: создаем interactor с несуществующим id
        let invalidId = UUID()
        let invalidInteractor = TaskDetailInteractor(taskId: invalidId, container: testManager.container)
        invalidInteractor.presenter = mockPresenter
        
        // When
        invalidInteractor.fetchTask()
        
        // Then
        let expectation = XCTestExpectation(description: "Wait for async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(self.mockPresenter.didFetchTaskCalled, "Presenter не должен быть вызыван для несуществующей задачи")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchTask_CalledOnMainThread() {
        // Given
        let threadExpectation = XCTestExpectation(description: "Called on main thread")
        mockPresenter.onDidFetchTask = {
            XCTAssertTrue(Thread.isMainThread, "didFetchTask должен вызываться на главном потоке")
            threadExpectation.fulfill()
        }
        // When
        sut.fetchTask()
        
        // Then
        wait(for: [threadExpectation], timeout: 1.0)
    }
    
    // MARK: - Tests: Update Task - Both Fields
    func testUpdateTask_BothFields_UpdatesSuccessfully() {
        // Given
        sut.fetchTask()
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        sut.updateTask("New Title", "New Body")
        
        // Then
        XCTAssertTrue(mockPresenter.didChangeTaskCalled, "didChangeTask должен быть вызван")
        
        // Проверяем что данные обновились в базе
        let updatedTask = getTaskFromDatabase(id: testTaskId)
        XCTAssertEqual(updatedTask?.title, "New Title")
        XCTAssertEqual(updatedTask?.body, "New Body")
    }
    
    func testUpdateTask_BothFields_CallsPresenter() {
        // Given
        sut.fetchTask()
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        mockPresenter.didChangeTaskCalled = false // Reset
        
        // When
        sut.updateTask("Title", "Body")
        
        XCTAssertTrue(mockPresenter.didChangeTaskCalled)
    }
    
    // MARK: - Tests: Update Task - Single Field
    func testUpdateTask_OnlyTitle_UpdatesOnlyTitle() {
        // Given
        sut.fetchTask()
        
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        sut.updateTask("New Title", nil)
        
        // Then
        let updatedTask = getTaskFromDatabase(id: testTaskId)
        XCTAssertEqual(updatedTask?.title, "New Title", "Title должен обновиться")
        XCTAssertEqual(updatedTask?.body, "Test Body", "Body не должен измениться")
    }
    
    func testUpdateTask_OnlyBody_UpdatesOnlyBody() {
        // Given
        sut.fetchTask()
        let fetchExpectation = XCTestExpectation(description: "Fetch complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fetchExpectation.fulfill()
        }
        wait(for: [fetchExpectation], timeout: 1.0)
        
        // When
        sut.updateTask(nil, "New Body")
        
        // Then
        let updatedTask = getTaskFromDatabase(id: testTaskId)
        XCTAssertEqual(updatedTask?.title, "Test Task", "Title не должен измениться")
        XCTAssertEqual(updatedTask?.body, "New Body", "Body должен обновиться")
    }
    
    func testUpdateTask_NilValues_DoesNotCrash() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            // When
            sut.updateTask(nil, nil)
            
            // Then: не должно быть крашей
            let updatedTask = getTaskFromDatabase(id: testTaskId)
            XCTAssertNotNil(updatedTask, "Задача должна остаться в базе")
            XCTAssertEqual(updatedTask?.title, "Test Task")
            XCTAssertEqual(updatedTask?.body, "Test Body")
        }
        
        // MARK: - Tests: Update Task - Date
        
        func testUpdateTask_UpdatesDateToNow() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            // Устанавливаем старую дату
            let oldDate = Date(timeIntervalSinceNow: -3600) // 1 час назад
            if let task = getTaskFromDatabase(id: testTaskId) {
                task.date = oldDate
                try? testManager.container.viewContext.save()
            }
            
            // When
            sut.updateTask("New Title", nil)
            
            // Then
            let updatedTask = getTaskFromDatabase(id: testTaskId)
            let updatedDate = updatedTask?.date
            
            XCTAssertNotNil(updatedDate, "Дата должна быть установлена")
            XCTAssertTrue(updatedDate! > oldDate, "Дата должна обновиться на более позднюю")
            
            // Проверяем что дата близка к текущему времени (в пределах 5 секунд)
            let timeDifference = abs(updatedDate!.timeIntervalSinceNow)
            XCTAssertLessThan(timeDifference, 5.0, "Дата должна быть близка к текущему времени")
        }
        
        // MARK: - Tests: Update Task - Without Fetch
        
        func testUpdateTask_WithoutFetch_DoesNothing() {
            // Given: НЕ вызываем fetchTask()
            let originalTask = getTaskFromDatabase(id: testTaskId)
            let originalTitle = originalTask?.title
            
            // When
            sut.updateTask("Should Not Update", "Should Not Update")
            
            // Then
            let task = getTaskFromDatabase(id: testTaskId)
            XCTAssertEqual(task?.title, originalTitle, "Задача не должна обновиться без предварительного fetch")
            XCTAssertFalse(mockPresenter.didChangeTaskCalled, "Presenter не должен быть вызван")
        }
        
        // MARK: - Tests: Delete Task
        
        func testDeleteTask_RemovesFromDatabase() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            // When
            sut.deleteTask()
            
            // Then
            XCTAssertTrue(mockPresenter.didChangeTaskCalled, "didChangeTask должен быть вызван")
            
            let deletedTask = getTaskFromDatabase(id: testTaskId)
            XCTAssertNil(deletedTask, "Задача должна быть удалена из базы")
        }
        
        func testDeleteTask_WithoutFetch_DoesNotDelete() {
            // Given: НЕ вызываем fetchTask()
            
            // When
            sut.deleteTask()
            
            // Then
            let task = getTaskFromDatabase(id: testTaskId)
            XCTAssertNotNil(task, "Задача не должна быть удалена без предварительного fetch")
            XCTAssertFalse(mockPresenter.didChangeTaskCalled, "Presenter не должен быть вызван")
        }
        
        func testDeleteTask_MultipleCalls_DoesNotCrash() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            // When: вызываем дважды
            sut.deleteTask()
            sut.deleteTask()
            
            // Then: не должно быть крашей
            let deletedTask = getTaskFromDatabase(id: testTaskId)
            XCTAssertNil(deletedTask)
        }
        
        // MARK: - Tests: Edge Cases
        
        func testInteractor_WithEmptyStrings_HandlesCorrectly() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            // When
            sut.updateTask("", "")
            
            // Then
            let updatedTask = getTaskFromDatabase(id: testTaskId)
            XCTAssertEqual(updatedTask?.title, "", "Должен принять пустую строку")
            XCTAssertEqual(updatedTask?.body, "", "Должен принять пустую строку")
        }
        
        func testInteractor_WithVeryLongStrings_HandlesCorrectly() {
            // Given
            sut.fetchTask()
            
            let fetchExpectation = XCTestExpectation(description: "Fetch complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchExpectation.fulfill()
            }
            wait(for: [fetchExpectation], timeout: 1.0)
            
            let longString = String(repeating: "a", count: 10000)
            
            // When
            sut.updateTask(longString, longString)
            
            // Then
            let updatedTask = getTaskFromDatabase(id: testTaskId)
            XCTAssertEqual(updatedTask?.title?.count, 10000)
            XCTAssertEqual(updatedTask?.body?.count, 10000)
        }
    }

// MARK: - Mock Presenter
class MockTaskDetailPresenter: TaskDetailPresenterProtocol {
    var didFetchTaskCalled = false
    var didChangeTaskCalled = false
    var fetchedTask: DataTask?
    var onDidFetchTask: (() -> Void)?
    
    func viewDidLoad() {}
    func userDidTapBack() {}
    
    func didFetchTask(_ task: DataTask) {
        didFetchTaskCalled = true
        fetchedTask = task
        onDidFetchTask?()
    }
    
    func didChangeTask() {
        didChangeTaskCalled = true
    }
    
    
}
