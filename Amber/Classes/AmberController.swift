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
    func push(_ viewController: UIViewController, animated: Bool)
    
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

public protocol AmberController: class, AmberPresenter, AmberPresentable {
    associatedtype Reducer: AmberReducer
    
    var store: AmberStore<Reducer> { get }
}

public extension AmberController{
    typealias State = Reducer.State
    typealias InputActionListener = (Reducer.InputAction) -> Void
    typealias OutputActionListener = (Reducer.OutputAction) -> Void
    
    public func initialize(with data: Reducer.State.RequiredData){
        store.initialize(on: self, data: data)
    }
    
    public var action: Subject<Reducer.Action, NoError> { return store.action }
    public var outputAction: Subject<Reducer.OutputAction, NoError> { return store.outputAction }
    public var transition: Subject<Reducer.Transition, NoError> { return store.transition }
    
    public var state: Signal<Reducer.State, NoError> { return store.state }
}
