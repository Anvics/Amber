//
//  AmberRouter.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

#if swift(>=4.2)
    public typealias AnimationOptions = UIView.AnimationOptions
#else
    public typealias AnimationOptions = UIViewAnimationOptions
#endif

enum AmberPresentationType{
    case present, show, embed
}

public protocol AmberEmbedder {
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
}

public extension AmberEmbedder{
    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView) -> Module.InputActionListener{
        return embed(module, data: data, inView: view, outputListener: nil)
    }

    func embed<Module: AmberController>(_ module: Module.Type, inView view: UIView, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void {
        return embed(module, data: (), inView: view, outputListener: outputListener)
    }
}

public protocol AmberRoutePerformer: AmberEmbedder {
    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: AnimationOptions)
    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener
    func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener

    func baseReplace(storyboardFile: String, storyboardID: String, animation: AnimationOptions)

    func baseShow(storyboardFile: String, storyboardID: String)

    func basePresent(storyboardFile: String, storyboardID: String)

    func close()

    func dismiss()
    func pop()
    func popToRoot()
}

public extension AmberRoutePerformer{
    func replace<Module: AmberController>(with module: Module.Type, animation: AnimationOptions = .transitionCrossDissolve) where Module.Reducer.State.RequiredData == Void{
        replace(with: module, data: (), animation: animation)
    }

    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData){
        replace(with: module, data: data, animation: .transitionCrossDissolve)
    }

    func baseReplace(storyboardFile: String, storyboardID: String){
        baseReplace(storyboardFile: storyboardFile, storyboardID: storyboardID, animation: .transitionCrossDissolve)
    }

    func show<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void{
        return show(module, data: (), outputListener: outputListener)
    }

    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData) -> Module.InputActionListener{
        return show(module, data: data, outputListener: nil)
    }

    func present<Module: AmberController>(_ module: Module.Type, outputListener: Module.OutputActionListener? = nil) -> Module.InputActionListener where Module.Reducer.State.RequiredData == Void{
        return present(module, data: (), outputListener: outputListener)
    }
}

public class FakeAmberRoutePerformer: AmberRoutePerformer{
    public func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: AnimationOptions){ }

    public func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }
    public func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{ return { _ in } }

    public func baseReplace(storyboardFile: String, storyboardID: String, animation: AnimationOptions){ }

    public func baseShow(storyboardFile: String, storyboardID: String){ }

    public func basePresent(storyboardFile: String, storyboardID: String){ }

    public func close(){ }

    public func dismiss(){ }
    public func pop(){ }
    public func popToRoot(){ }
}

final class AmberRoutePerformerImplementation<T: AmberController, U: AmberController>: AmberRoutePerformer {
    weak var controller: T?
    weak var embedder: U?

    init(controller: T, embedder: U) {
        self.controller = controller
        self.embedder = embedder
    }

    func replace<Module: AmberController>(with module: Module.Type, data: Module.Reducer.State.RequiredData, animation: AnimationOptions){
        let (vc, _) = AmberControllerHelper.create(module: module, data: data, outputListener: nil)
        replaceWith(vc, animation: animation)
    }

    func show<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .show, outputListener: outputListener)
    }

    func present<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        return route(module: module, data: data, presentation: .present, outputListener: outputListener)
    }

    func baseReplace(storyboardFile: String, storyboardID: String, animation: AnimationOptions){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        replaceWith(vc, animation: animation)
    }

    func baseShow(storyboardFile: String, storyboardID: String){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        controller?.show(vc, animated: true)
    }

    func basePresent(storyboardFile: String, storyboardID: String){
        let vc = createController(storyboardFile: storyboardFile, storyboardID: storyboardID)
        controller?.present(vc, animated: true, completion: nil)
    }

    func close() { controller?.close(animated: true) }

    func dismiss(){ controller?.dismiss(animated: true) }

    func pop() { controller?.pop(animated: true) }

    func popToRoot() { controller?.popToRoot(animated: true) }

    func embed<Module: AmberController>(_ module: Module.Type, data: Module.Reducer.State.RequiredData, inView view: UIView, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, route: controller!, outputListener: outputListener)
        guard let uicontroller = controller as? UIViewController else { fatalError() }
        vc.embedIn(view: view, container: uicontroller)
        return output
    }

    private func replaceWith(_ vc: UIViewController, animation: AnimationOptions){
        guard let currentVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        UIView.transition(from: currentVC.view, to: vc.view, duration: 0.4, options: animation) { _ in
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }

    private func createController(storyboardFile: String, storyboardID: String) -> UIViewController{
        return UIStoryboard(name: storyboardFile, bundle: nil).instantiateViewController(withIdentifier: storyboardID)
    }

    fileprivate func route<Module: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, presentation: AmberPresentationType, outputListener: Module.OutputActionListener?) -> Module.InputActionListener{
        let (vc, output) = AmberControllerHelper.create(module: module, data: data, outputListener: outputListener)

        switch presentation {
        case .present: controller?.present(vc, animated: true, completion: nil)
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

