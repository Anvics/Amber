//
//  AmberStore.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import Foundation
import ReactiveKit

public final class AmberStore<Reducer: AmberReducer>{
    var state: Signal<Reducer.State, NoError> { return _state.toSignal().ignoreNil() }
    
    public let action = Subject<Reducer.Action, NoError>()
    public let outputAction = Subject<Reducer.OutputAction, NoError>()
    public let transition = Subject<Reducer.Transition, NoError>()
    
    fileprivate var outputListener: ((Reducer.OutputAction) -> Void)?
    fileprivate var routePerformer: AmberRoutePerformer!
    
    fileprivate let _state = Property<Reducer.State?>(nil)
    
    fileprivate let reducer: Reducer
    private let router: AmberRouterBlock<Reducer>
    private var isInitialized = false
    
    typealias ActionBlock = (Reducer.Action) -> Void
    typealias OutputActionBlock = (Reducer.OutputAction) -> Void
    typealias TransitionBlock = (Reducer.Transition) -> Void
    
    public init<R: AmberRouter>(reducer: Reducer, router: R) where R.Reducer == Reducer{
        self.reducer = reducer
        self.router = router.perform
        subscribe()
    }
    
    ///Use only for tests
    public init<R: AmberRouter>(reducer: Reducer, router: R, requiredData: Reducer.State.RequiredData) where R.Reducer == Reducer{
        self.reducer = reducer
        self.router = router.perform
        subscribe()
        routePerformer = FakeAmberRoutePerformer()
        sharedInitialize(data: requiredData)
    }
    
    public func initialize(with data: Reducer.State.RequiredData, routePerformer: AmberRoutePerformer){
        if isInitialized { return }
        isInitialized = true
        self.routePerformer = routePerformer
        sharedInitialize(data: data)
    }
    
    public func currentState() -> Reducer.State{
        guard let state = _state.value else {
            fatalError("Не удалось получить текущее состояние. Если ошибка произошла при запуске приложения, убедитесь в том что в начальном контроллере в самом начале viewDidLoad есть строчка store.initialize(on: self)")
        }
        return state
    }
    
    public func perform(action: Reducer.Action){
        initiateChangeState(action: action) { (state, router, actionPerf, outActionPerf, transitionPerf) in
            self.reducer.reduce(action: action, state: state, performTransition: transitionPerf, performAction: actionPerf, performOutputAction: outActionPerf)
        }
    }
    
    public func performInput(action: Reducer.InputAction){
        initiateChangeState(action: action) { (state, router, actionPerf, outActionPerf, _) in
            self.reducer.reduceInput(action: action, state: state, performAction: actionPerf, performOutputAction: outActionPerf)
        }
    }
    
    public func performOutput(action: Reducer.OutputAction){
        processAction(action) {
            self.outputListener?(action)
        }
    }
    
    public func perform(transition: Reducer.Transition){
        processAction(transition) {
            self.router(transition, self.routePerformer, self.reducer, self.perform)
        }
    }
}

extension AmberStore{
    fileprivate func subscribe(){
        let _ = action.observeNext { [weak self] in self?.perform(action: $0) }
        let _ = outputAction.observeNext { [weak self] in self?.performOutput(action: $0) }
        let _ = transition.observeNext { [weak self] in self?.perform(transition: $0) }
    }

    fileprivate func processAction(_ action: Any, actionBlock: @escaping () -> Void){
        Amber.main.process(state: currentState(), beforeEvent: action)
        Amber.main.perform(event: action, onState: currentState(), route: routePerformer) {
            actionBlock()
            Amber.main.process(state: self.currentState(), afterEvent: action, route: self.routePerformer)
        }
    }

    fileprivate func initiateChangeState(action: AmberAction, newState: @escaping (Reducer.State, AmberRoutePerformer, @escaping ActionBlock, @escaping OutputActionBlock, @escaping TransitionBlock) -> Reducer.State){
        processAction(action) { self.changeState(action: action, newState: newState) }
    }
    
    fileprivate func changeState(action: AmberAction, newState: (Reducer.State, AmberRoutePerformer, @escaping ActionBlock, @escaping OutputActionBlock, @escaping TransitionBlock) -> Reducer.State){
        let stateToUse = currentState()
        var isPerformed = false
        var delayedActions: [Reducer.Action] = []
        var delayedOutputActions: [Reducer.OutputAction] = []
        var delayedTransitions: [Reducer.Transition] = []
        
        let ns = newState(stateToUse, routePerformer, { a in
            if isPerformed{ self.perform(action: a) }
            else { delayedActions.append(a) }
        }, { a in
            if isPerformed{ self.performOutput(action: a) }
            else { delayedOutputActions.append(a) }
        }, { t in
            if isPerformed { self.perform(transition: t) }
            else{ delayedTransitions.append(t) }
        })
        
        _state.value = ns
        
        isPerformed = true
        delayedActions.forEach(perform)
        delayedOutputActions.forEach(performOutput)
        delayedTransitions.forEach(perform)
    }
    
    fileprivate func sharedInitialize(data: Reducer.State.RequiredData){
        _state.value = Reducer.State(data: data)
        
        reducer.initialize(state: currentState(), performAction: perform, performOutputAction: performOutput)
    }
}

public class AmberControllerHelper{
    public static func create<Module: AmberController>(module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener? = nil) -> (UIViewController, Module.InputActionListener){
        return create(module: module, data: data, outputListener: outputListener, router: { $0 })
    }
    
    public static func create<Module: AmberController, Route: AmberController>(module: Module.Type, data: Module.State.RequiredData, route: Route, outputListener: Module.OutputActionListener? = nil) -> (UIViewController, Module.InputActionListener){
        return create(module: module, data: data, outputListener: outputListener, router: { _ in route })
    }
    
    private static func create<Module: AmberController, Route: AmberController>(module: Module.Type, data: Module.State.RequiredData, outputListener: Module.OutputActionListener? = nil, router: (Module) -> Route) -> (UIViewController, Module.InputActionListener){
        
        let vc = Module.instantiate()
        vc.store.initialize(with: data, routePerformer: AmberRoutePerformerImplementation(controller: router(vc), embedder: vc))
        vc.store.outputListener = outputListener
        
        guard let uivc = vc as? UIViewController else {
            fatalError("На текущий момент возможно произвести переход/встроить только UIViewController. Попытались создать \(type(of: vc))")
        }
        
        return (uivc, vc.store.performInput)
    }
}

