//
//  TaskMainView.swift
//  ToDoList
//
//  Created by Эдвард on 25.11.2025.
//
import SwiftUI

struct TaskMainView: View {
    
    @StateObject private var viewModel = TaskViewModel()
    
    @State private var path: [UUID] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                List {
                    ForEach(viewModel.filteredTasks) { task in
                        if let taskId = task.id {
                            VStack(spacing: 0) {
                                Button {
                                    path.append(taskId)
                                } label: {
                                    TaskRow(
                                        task: task,
                                        dateString: viewModel.formatter.string(from: task.date ?? Date()),
                                        toggleAction: { viewModel.toggleTaskCompletion(at: taskId) }
                                        
                                    )
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.removeTask(at: taskId)
                                    } label: {
                                        Image(systemName: "trash")
                                        
                                    }
                                }.tint(.red)
                                
                                // MARK: - Контекстное меню
                                    .contextMenu {
                                        Button {
                                            path.append(taskId)
                                        } label: {
                                            Label("Редактировать", systemImage: "square.and.pencil")
                                        }
                                        Button {
                                            // share
                                        } label: {
                                            Label("Поделиться", systemImage: "square.and.arrow.up")
                                        }
                                        Button(role: .destructive) {
                                            viewModel.removeTask(at: taskId)
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                        
                                    } preview: {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(task.title ?? "")
                                                .font(.system(size: 18))
                                                .bold()
                                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                                .strikethrough(task.isCompleted)
                                            
                                            Text(task.body ?? "")
                                                .font(.system(size: 14))
                                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .lineLimit(2)
                                            Text(viewModel.formatter.string(from: task.date ?? Date()))
                                                .font(.system(size: 14))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .frame(maxWidth: UIScreen.main.bounds.width)
                                        
                                    }
                                
                                
                                if task != viewModel.filteredTasks.last {
                                    Divider()
                                        .background(Color.gray)
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                } // List
                .scrollIndicators(.hidden)
                .padding(.horizontal)
                .listStyle(.plain)
                .searchable(text: $viewModel.searchText, prompt: "Search")

                //MARK: - Нижняя панель
                Divider()
                    .background(Color.gray)
                ZStack {
                    Text(viewModel.taskCountText(for: viewModel.filteredTasks.count))
                        .foregroundStyle(.primary)
                        .font(.system(size: 14))
                    HStack {
                        Spacer()
                        Button {
                            let newTaskId = viewModel.createNewTask()
                            path.append(newTaskId)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 26))
                                .foregroundStyle(.yellow)
                                .padding(.trailing, 26)
                        }
                    }
                    HStack {
                        Button {
                            viewModel.resetAndReload()
                        } label: {
                            Text("☠")
                                .font(.system(size: 26))
                                .foregroundStyle(.yellow)
                                .padding(.leading, 26)
                                .opacity(0.05)
                        }
                        Spacer()
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .padding(.top)
                .background(Color.gray.opacity(0.2))
            }
            
            .navigationDestination(for: UUID.self) { taskId in
                TaskDetailView(taskId: taskId, viewModel: viewModel)
            }
            .navigationTitle("Задачи")
            
        }
        .scrollDismissesKeyboard(.immediately)
        .tint(.yellow)
        
    }
    
}

// MARK: - Структура ячейки
struct TaskRow: View {
    let task: TaskModel
    let dateString: String
    let toggleAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                .font(.title)
                .fontWeight(.thin)
                .foregroundStyle(task.isCompleted ? .yellow : .gray)
                .onTapGesture { toggleAction() }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "")
                    .font(.system(size: 18))
                    .bold()
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                Text(task.body ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                Text(dateString)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical) // Важный!
    }
} //viewModel.formatter.string(from: task.date)
#Preview {
    TaskMainView()
}
