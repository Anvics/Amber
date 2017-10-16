//
//  AmberRouter.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

enum AmberPresentationType{
    case push, present, show, embed
}

public protocol AmberEmbedder {
    func embed<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, view: UIView, input: U.OutputBlock?) -> U.InputBlock
}

extension AmberEmbedder{
    func embed<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, view: UIView) -> U.InputBlock{
        return embed(screen, data: data, view: view, input: nil)
    }
    
    func embed<U: AmberController>(_ screen: U.Type, view: UIView, input: U.OutputBlock? = nil) -> U.InputBlock where U.StoreState.RequiredData == Void{
        return embed(screen, data: (), view: view, input: input)
    }
}

public protocol AmberRoutePerformer: AmberEmbedder {
    func replace<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, animation: UIViewAnimationOptions)
    
    func show<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock
    
    func push<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock
    func present<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock
    
    func close()
    
    func dismiss()
    func pop()
    func popToRoot()
}

extension AmberRoutePerformer{
    func replace<U: AmberController>(_ screen: U.Type, animation: UIViewAnimationOptions = .transitionCrossDissolve) where U.StoreState.RequiredData == Void{
        replace(screen, data: (), animation: animation)
    }
    
    func replace<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData){
        replace(screen, data: data, animation: .transitionCrossDissolve)
    }
    
    func show<U: AmberController>(_ screen: U.Type, input: U.OutputBlock? = nil) -> U.InputBlock where U.StoreState.RequiredData == Void{
        return show(screen, data: (), input: input)
    }
    
    func show<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData) -> U.InputBlock{
        return show(screen, data: data, input: nil)
    }
    
    func push<U: AmberController>(_ screen: U.Type, input: U.OutputBlock? = nil) -> U.InputBlock where U.StoreState.RequiredData == Void{
        return push(screen, data: (), input: input)
    }
    
    func present<U: AmberController>(_ screen: U.Type, input: U.OutputBlock? = nil) -> U.InputBlock where U.StoreState.RequiredData == Void{
        return present(screen, data: (), input: input)
    }
}

public class FakeAmberRoutePerformer: AmberRoutePerformer{
    public func embed<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, view: UIView, input: U.OutputBlock?) -> U.InputBlock{ return { _ in } }
    public func replace<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, animation: UIViewAnimationOptions){ }
    
    public func show<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{ return { _ in } }
    public func push<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{ return { _ in } }
    public func present<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{ return { _ in } }
    
    public func close(){ }
    
    public func dismiss(){ }
    public func pop(){ }
    public func popToRoot(){ }
}

final class AmberRoutePerformerImplementation<T: AmberController>: AmberRoutePerformer {
    weak var controller: T?
    
    init(controller: T) {
        self.controller = controller
    }
    
    func replace<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, animation: UIViewAnimationOptions){
        guard let currentVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        let (vc, _) = AmberControllerHelper.create(type: screen, data: data, input: nil)
        UIView.transition(from: currentVC.view, to: vc.view, duration: 0.4, options: animation) { _ in
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }
    
    func show<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{
        return route(type: screen, data: data, presentation: .show, input: input)
    }
    
    func push<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{
        return route(type: screen, data: data, presentation: .push, input: input)
    }
    
    func present<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, input: U.OutputBlock?) -> U.InputBlock{
        return route(type: screen, data: data, presentation: .present, input: input)
    }
    
    func close() { controller?.close(animated: true) }
    
    func dismiss(){ controller?.dismiss(animated: true) }
    
    func pop() { controller?.pop(animated: true) }
    
    func popToRoot() { controller?.popToRoot(animated: true) }
    
    func embed<U: AmberController>(_ screen: U.Type, data: U.StoreState.RequiredData, view: UIView, input: U.OutputBlock?) -> U.InputBlock{
        let (vc, output) = AmberControllerHelper.create(type: screen, data: data, routerPerformer: self, input: input)
        guard let uicontroller = controller as? UIViewController else { fatalError() }
        vc.embedIn(view: view, container: uicontroller)
        return output
    }
    
    fileprivate func route<U: AmberController>(type: U.Type, data: U.StoreState.RequiredData, presentation: AmberPresentationType, input: U.OutputBlock?) -> U.InputBlock{
        let (vc, output) = AmberControllerHelper.create(type: type, data: data, input: input)
        
        switch presentation {
        case .present: controller?.present(vc, animated: true, completion: nil)
        case .push: controller?.push(vc, animated: true)
        case .show: controller?.show(vc, animated: true)
        case .embed: fatalError("Call embed instead of route")
        }
        return output
    }
    
}

public protocol AmberRouter{
    associatedtype Reducer: AmberReducer
    
    func perform(transition: Reducer.Transition, route: AmberRoutePerformer, reducer: Reducer, performAction: @escaping (Reducer.Action) -> Void)
}

typealias AmberRouterBlock<Reducer: AmberReducer> = (Reducer.Transition, AmberRoutePerformer, Reducer, @escaping (Reducer.Action) -> Void) -> Void
