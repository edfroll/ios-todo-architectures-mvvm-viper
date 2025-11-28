//
//  TaskMainView.swift
//  ToDoList
//
//  Created by Эдвард on 18.09.2025.
import SwiftUI

// MARK: - Главная структура
struct TaskMainView: View {
    
    @StateObject var vm = TaskViewModel()
    
    @State private var path: [UUID] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                List(vm.filteredTasks) { task in
                    VStack {
                        TaskRow(
                            task: task, vm: vm, path: $path)
                        if task != vm.tasks.last {
                            Divider()
                                .background(Color.gray)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    
                }
                .listStyle(.plain)
                .searchable(text: $vm.searchText, prompt: "Search")
                
                BottomBar(vm: vm, path: $path)
            }
            .navigationDestination(for: UUID.self) { taskId in
                TaskDetailView(taskId: taskId, vm: vm)
            }
            .navigationTitle("Задачи")
        }
        .scrollDismissesKeyboard(.immediately)
        .tint(.yellow)
    }
}
// MARK: - Готовая структура ячейки
struct TaskRow: View {
    var task: TaskDisplayModel
    let vm: TaskViewModel
    @Binding var path: [UUID]
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                path.append(task.id)
            } label: {
                RawTaskRow(
                    task: task,
                    toggleAction: { vm.toggleTaskCompletion(at: task.id) }
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    vm.deleteTask(at: task.id)
                } label: {
                    Image(systemName: "trash")
                }
            }
            .tint(.red)
            // Контестное меню
            .contextMenu {
                Button {
                    print("User did tap edit!")
                } label: {
                    Label("Редактировать", systemImage: "square.and.pencil")
                }
                Button(role: .destructive) {
                    vm.deleteTask(at: task.id)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } preview: {
                VStack(alignment: .leading, spacing: 12) {
                    Text(task.title)
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                    Text(task.body)
                        .font(.system(size: 14))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    Text(task.dateString)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .frame(maxWidth: UIScreen.main.bounds.width)
            }
        }
    }
}
// MARK: - Сырая структура ячейки
struct RawTaskRow: View {
    let task: TaskDisplayModel
    let toggleAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle" : "circle")
                .font(.title)
                .fontWeight(.thin)
                .foregroundStyle(task.isCompleted ? .yellow : .gray)
                .onTapGesture { toggleAction() }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 18))
                    .bold()
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                
                Text(task.body)
                    .font(.system(size: 14))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                Text(task.dateString)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical)
    }
}
//MARK: - Нижняя панель
struct BottomBar: View {
    @ObservedObject var vm: TaskViewModel
    @Binding var path: [UUID]
    
    @State private var rotationAngle: Double = 0
    
    
    var body: some View {
        ZStack {
            Text(vm.taskCountText(for: vm.tasks.count))
                .foregroundStyle(.primary)
                .font(.system(size: 14))
            HStack {
                Spacer()
                Button {
                    path.append(vm.createNewTask())
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 26))
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 26)
                }
            }
            HStack {
                Button {
                    vm.resetAndReload()
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 26))
                        .foregroundStyle(vm.isReloading ? .gray.opacity(0.5) : .gray)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .padding(.leading, 26)
                .disabled(vm.isReloading)
                .onChange(of: vm.isReloading) { oldValue, isReloading in
                    if isReloading {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    } else {
                        withAnimation(.linear(duration: 0.3)) {
                            rotationAngle = 0
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.top)
        .background(Color.gray.opacity(0.2).ignoresSafeArea(edges: .bottom))
    }
}
#Preview {
    TaskMainView()
}

