//
//  TaskMainView.swift
//  ToDoList
//
//  Created by Эдвард on 24.11.2025.
//

import SwiftUI

// MARK: - Main structure
struct TaskMainView: View {
    @StateObject var vm: TaskMainPresenter
    @StateObject var router: TaskMainRouter
    
    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                List(vm.displayTasks) { task in
                    VStack {
                        TaskRow(
                            task: task, vm: vm)
                        
                        if task != vm.displayTasks.last {
                            Divider()
                                .background(Color.gray)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    
                }
                .listStyle(.plain)
                .searchable(text: $vm.searchText, prompt: "Search")
                .onChange(of: vm.searchText) {
                    vm.userDidSearch()
                }
                
                BottomBar(vm: vm)
            }
            .navigationDestination(for: UUID.self) { taskId in
                TaskDetailRouter.createModule(taskId: taskId)
            }
            .navigationTitle("Задачи")
        }
        .scrollDismissesKeyboard(.immediately)
        .tint(.yellow)
    }
    
}
// MARK: - Completed Structure
struct TaskRow: View {
    let task: TaskDisplayModel
    let vm: TaskMainPresenterProtocol
    var body: some View {
        VStack(spacing: 0) {
            Button {
                vm.userDidTapEdit(for: task.id)
            } label: {
                RawTaskRow(
                    task: task,
                    toggleAction: { vm.userDidTapToggleCompletion(for: task.id) }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    vm.userDidTapDelete(for: task.id)
                } label: {
                    Image(systemName: "trash")
                }
            }
            .tint(.red)
            .contextMenu {
                Button {
                    vm.userDidTapEdit(for: task.id)
                } label: {
                    Label("Редактировать", systemImage: "square.and.pencil")
                }
                Button(role: .destructive) {
                    vm.userDidTapDelete(for: task.id)
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
// MARK: - Row Structure
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
//MARK: - BottomBar
struct BottomBar: View {
    @ObservedObject var vm: TaskMainPresenter
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            Text(vm.taskCountText(for: vm.displayTasks.count))
                .foregroundStyle(.primary)
                .font(.system(size: 14))
            HStack {
                Spacer()
                Button {
                    vm.userDidTapAddTask()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 26))
                        .foregroundStyle(.yellow)
                        .padding(.trailing, 26)
                }
            }
            HStack {
                Button {
                    vm.userDidTapReset()
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
    TaskMainRouter.build()
}
