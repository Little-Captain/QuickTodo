/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import RxSwift
import RxDataSources
import Action

typealias TaskSection = AnimatableSectionModel<String, TaskItem>

struct TasksViewModel {
    
    let sceneCoordinator: SceneCoordinatorType
    let taskService: TaskServiceType
    
    lazy var editAction: Action<TaskItem, Swift.Never> = { this in
        return Action { task in
            let editViewModel = EditTaskViewModel(
                task: task,
                coordinator: this.sceneCoordinator,
                updateAction: this.onUpdateTitle(task: task)
            )
            return this.sceneCoordinator
                .transition(to: .editTask(editViewModel), type: .modal)
                .asObservable()
        }
    }(self)
    
    // chanllenge 1
    lazy var deleteAction: Action<TaskItem, Void> = { service in
        return Action { service.delete(task: $0) }
    }(self.taskService)
    
    var sectionedItems: Observable<[TaskSection]> {
        return taskService
            .tasks()
            .map {
                let dueTasks = $0
                    .filter("checked == nil")
                    .sorted(byKeyPath: "added", ascending: false)
                let doneTasks = $0
                    .filter("checked != nil")
                    .sorted(byKeyPath: "checked", ascending: false)
                return [
                    TaskSection(model: "Due Tasks", items: dueTasks.toArray()),
                    TaskSection(model: "Done Tasks", items: doneTasks.toArray())
                ]
        }
    }
    
    
    init(taskService: TaskServiceType, coordinator: SceneCoordinatorType) {
        self.taskService = taskService
        self.sceneCoordinator = coordinator
    }
    
    func onCreateTask() -> CocoaAction {
        return CocoaAction { _ in
            self.taskService
                .createTask(title: "")
                .flatMap { task -> Observable<Void> in
                    let editViewModel = EditTaskViewModel(
                        task: task,
                        coordinator: self.sceneCoordinator,
                        updateAction: self.onUpdateTitle(task: task),
                        cancelAction: self.onDelete(task: task)
                    )
                    return self.sceneCoordinator
                        .transition(to: .editTask(editViewModel), type: .modal)
                        .asObservable()
                        .map { _ in }
            }
        }
    }
    
    func onToggle(task: TaskItem) -> CocoaAction {
        return CocoaAction {
            return self.taskService.toggle(task: task).map { _ in }
        }
    }
    
    func onDelete(task: TaskItem) -> CocoaAction {
        return CocoaAction {
            return self.taskService.delete(task: task)
        }
    }
    
    func onUpdateTitle(task: TaskItem) -> Action<String, Void> {
        return Action { newTitle in
            return self.taskService.update(task: task, title: newTitle).map { _ in }
        }
    }
    
}
