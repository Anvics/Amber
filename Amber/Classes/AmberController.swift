//
//  AmberController.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit
import ReactiveKit

public protocol AmberPresenter: class {
    func embedIn(view: UIView, container: UIViewController)
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)?)
    
    func show(_ viewController: UIViewController, animated: Bool)
    
    func close(animated: Bool)
    
    func dismiss(animated: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
}

public protocol AmberPresentable {
    static var storyboardFile: String { get }
    static var storyboardID: String { get }
}

public protocol AmberController: AmberPresenter, AmberPresentable {
    associatedtype Reducer: AmberReducer
    
    var store: AmberStore<Reducer> { get }
}

public extension AmberController{
    typealias InputActionListener = (Reducer.InputAction) -> Void
    typealias OutputActionListener = (Reducer.OutputAction) -> Void
    
    func initialize(with data: Reducer.State.RequiredData){
        store.initialize(with: data, routePerformer: AmberRoutePerformerImplementation(controller: self, embedder: self))
    }
    
    func perform(action: Reducer.Action){
        store.perform(action: action)
    }
    
    func perform(transitions: Reducer.Transition...){
        transitions.forEach(store.perform)
    }
    
    func perform(outputAction: Reducer.OutputAction){
        store.performOutput(action: outputAction)
    }
    
    func field<T: Equatable>(_ extract: @escaping (Reducer.State) -> T) -> Signal<T, Never>{
        return state.map(extract).removeDuplicates()
    }
    
    var action: Subject<Reducer.Action, Never> { return store.action }
    var outputAction: Subject<Reducer.OutputAction, Never> { return store.outputAction }
    var transition: Subject<Reducer.Transition, Never> { return store.transition }
    
    var state: Signal<Reducer.State, Never> { return store.state }
    
    var currentState: Reducer.State { return store.currentState() }
}

public extension AmberController where Reducer.State.RequiredData == Void{
    func initialize(){
        store.initialize(with: (), routePerformer: AmberRoutePerformerImplementation(controller: self, embedder: self))
    }
}

//For hardcore users
infix operator ~>
infix operator *>

public func *><T: AmberController>(left: (T, UIButton), right: T.Reducer.Action){
    left.1.reactive.tap.replaceElements(with: right).bind(to: left.0.action)
}

public func *><T: AmberController, R>(left: (T, Signal<R, Never>), right: T.Reducer.Action){
    left.1.replaceElements(with: right).bind(to: left.0.action)
}

public func *><T: AmberController, R>(left: (T, Signal<R, Never>), right: @escaping (R) -> T.Reducer.Action){
    left.1.map(right).bind(to: left.0.action)
}


public func ~><T: AmberController>(left: (T, UIButton), right: T.Reducer.Transition){
    left.1.reactive.tap.replaceElements(with: right).bind(to: left.0.transition)
}

public func ~><T: AmberController, R>(left: (T, Signal<R, Never>), right: T.Reducer.Transition){
    left.1.replaceElements(with: right).bind(to: left.0.transition)
}

public func ~><T: AmberController, R>(left: (T, Signal<R, Never>), right: @escaping (R) -> T.Reducer.Transition){
    left.1.map(right).bind(to: left.0.transition)
}
