//
//  AmberControllerHelper.swift
//  TrainBrain
//
//  Created by Nikita Arkhipov on 09.10.2017.
//  Copyright © 2017 Nikita Arkhipov. All rights reserved.
//

import UIKit

extension AmberPresentable{
    public static func instantiate() -> Self{
        let sb = UIStoryboard(name: storyboardFile, bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: storyboardID) as? Self else { fatalError() }
        return vc
    }
}

extension UIViewController: AmberPresenter{
    public func push(_ viewController: UIViewController, animated: Bool){
        navigationController?.pushViewController(viewController, animated: animated)
    }

    public func embedIn(view: UIView, container: UIViewController){
        self.view.frame = view.bounds
        container.addChildViewController(self)
        view.addSubview(self.view)
        view.embeddedControllers.append(self)
        didMove(toParentViewController: container)
    }
    
    public func show(_ viewController: UIViewController, animated: Bool){
        if navigationController != nil { push(viewController, animated: true) }
        else { present(viewController, animated: true, completion: nil) }
    }
    
    public func close(animated: Bool){
        if let nav = navigationController{ nav.popViewController(animated: animated) }
        else if parent != nil { unembed() }
        else{ dismiss(animated: animated, completion: nil) }
    }
    
    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
    
    public func pop(animated: Bool){
        navigationController?.popViewController(animated: animated)
    }
    
    public func popToRoot(animated: Bool){
        navigationController?.popToRootViewController(animated: animated)
    }
    
    func unembed(shouldModifyEmbedArray: Bool = true){
        removeFromParentViewController()
        if let index = view.superview?.embeddedControllers.index(of: self), shouldModifyEmbedArray{
            view.superview?.embeddedControllers.remove(at: index)
        }
        view.removeFromSuperview()
        didMove(toParentViewController: nil)
    }
}

private var UIView_Associated_EmbedControllers: UInt8 = 0
extension UIView{
    var embeddedControllers: [UIViewController]{
        get {
            return objc_getAssociatedObject(self, &UIView_Associated_EmbedControllers) as? [UIViewController] ?? []
        }
        set {
            objc_setAssociatedObject(self, &UIView_Associated_EmbedControllers, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public class AmberControllerHelper{
    public static func create<Module: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener? = nil) -> (UIViewController, Module.InputActionListener){
        return create(module: module, data: data, outputListener: outputListener, router: { $0 })
    }
    
    public static func create<Module: AmberController, Route: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, route: Route, outputListener: Module.OutputActionListener? = nil) -> (UIViewController, Module.InputActionListener){
        return create(module: module, data: data, outputListener: outputListener, router: { _ in route })
    }
    
    private static func create<Module: AmberController, Route: AmberController>(module: Module.Type, data: Module.Reducer.State.RequiredData, outputListener: Module.OutputActionListener? = nil, router: (Module) -> Route) -> (UIViewController, Module.InputActionListener){
        
        let vc = Module.instantiate()
        vc.store.initialize(with: data, routePerformer: AmberRoutePerformerImplementation(controller: router(vc), embedder: vc))
        vc.store.outputListener = outputListener
        
        guard let uivc = vc as? UIViewController else {
            fatalError("На текущий момент возможно произвести переход/встроить только UIViewController. Попытались создать \(type(of: vc))")
        }
        
        return (uivc, vc.store.performInput)
    }
}
