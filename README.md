![](Assets/amberLogo2.png)
# Amber

![](https://img.shields.io/badge/Swift-4.2-orange.svg)
[![Version](https://img.shields.io/cocoapods/v/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)
[![License](https://img.shields.io/cocoapods/l/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)
[![Platform](https://img.shields.io/cocoapods/p/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)

## Overview

Amber is flexible architecture based on Elm & Flux ideas and developed specifically for iOS. It separetes components of a module into six parts: 


**State**: is plain struct responsible for holding all data based on which interface is drawn.

**Actions**: are events that can happen in module: button press, data loaded, etc. 

**Reducer**: is class responsible for processing Actions and for initial setup.

**Transitions**: are types of transitions that can happen in module.

**Router**: is class responsible for processing Transitions

**Store**: holds reference to Reducer, Router and current State.

**Controller**: is plain mapping of the state into the user interface. It subscribes to current state and updates view accordingly to the new state. It also responsible for sending Actions and Transitions to the Store. 

## Benefits

* makes application behavior more predictable;

* code stays good structured as your application grows;

* allow you to intercept all application events;

* easier to refactor and modify your code.

## Schema
![](Assets/overview.png)

## In depth overview

### State

State is a struct that stores all data needed for your module. For example:

```Swift
struct FeedState: AmberState {
    var description: String {
        return "isLoading: \(isLoading), items: \(feedItems.count)"
    }
    
    var isLoading = true
    var feedItems: [FeedItem] = []

    init(data: Void) { }
}
```
State should not store any UI components but it should store all the data needed to unambiguously display the view i.e. for the same state your view should always looks the same. 

### Actions

Action is enum that lists all actions that can happen inside a module. For example:

```Swift
enum FeedAction: AmberAction{
    case itemsLoaded([FeedItem])
    case like(Int)
}
```
action cases should contain any data needed to process them.

### Reducer

Reducer is a class that is mainly responsible for processing Actions. It takes as input a current state and an action which is occurred and should return new state.

```Swift
class FeedReducer: AmberReducer{
    /* other code */
    
    func reduce(action: FeedAction, state: FeedState,
                performTransition: @escaping (FeedTransition) -> Void,
                performAction: @escaping (FeedAction) -> Void,
                performOutputAction: @escaping (FeedOutputAction) -> Void) -> FeedState{
        var newState = state
        switch action {
        case .itemsLoaded(let items):
            newState.isLoading = false
            newState.feedItems = items
        case .like(let index):
            let item = newState.feedItems[index]
            item.isLiked = !item.isLiked
        }
        return newState
    }
    
    /* other code */
}
```
Reduce function should be [pure function](https://en.wikipedia.org/wiki/Pure_function). Reducer is not required to change state for every action, for any of them it can perform transitions:

```Swift
        case .showUser(let user):
            if user.isCurrent { performTransition(.profile) }
            else { performTransition(.information(user)) } 
```
or perform other actions:
```Swift
        case .reloadItems:
            itemsLoader.load(completion: { items in performAction(.itemsLoaded(items)) })
```

### Transition

Transition is enum that lists all transition that can happen in current module. For example:

```Swift
enum FeedTransition: AmberTransition{
    case profile
    case showPhoto(UIImage)
}
```
Transitions like actions should contain any data needed to process them

### Router

Router is class that performs transitions and processes output actions from presented/embedded modules. For example:
```Swift
class FeedRouter: AmberRouter{
    func perform(transition: FeedTransition,
                 route: AmberRoutePerformer,
                 reducer: FeedReducer,
                 performAction: @escaping (FeedAction) -> Void){
        switch transition {
        case .profile: _ = route.show(ProfileModule)
        case .showPhoto(let image): _ = route.show(FeedItemModule, data: image)
        }
    }
}
```

### Store

Store is responsible for recieving actions and transitions, storing current state, router and reducer. Store is the only component that you should not override yourself – it is provided and implemented by Amber itself. You initialize store with Reducer and Router objects in your Controller as follows:

```Swift
final class FeedController: UIViewController, AmberController {

    let store = AmberStore(reducer: FeedReducer(), router: FeedRouter())
```


### Controller

Controller is the UIViewController subclass. It is responsible for binding state to UI and mapping user actions Actions/Transitions cases and sending them to store. For example:

```Swift
//MARK: - Bindings
extension FeedController{
    func bind(){
        profileButton.reactive.tap
            .replace(with: .profile)
            .bind(to: transition)
        
        state.map { $0.isLoading }.bind(to: activityIndicator.reactive.isAnimating)
    }
}
```

There are two ways Controller can send Action events to Store:
1) bind any event (like button tap) to Store property `action` in a reactive way:
```Swift
plusButton.reactive.tap
    .replace(with: .increaseAmount)
    .bind(to: action)
```
2) dispatch `Action` manually:
```Swift
extension FeedController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        store.perform(action: .like(indexPath.row))
    }
}    
```        
The same is true about transitions:
```Swift
extension FeedController{
    func bind(){
        profileButton.reactive.tap
            .replace(with: .profile)
            .bind(to: transition)
    }
}

extension FeedController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if let image = store.currentState().feedItems[indexPath.row].image{
            store.perform(transition: .showPhoto(image))
        }
    }
}
```

Controller should not store in self no other properties than UIView objects. All other properties should be places in State.
Most preferred way to work with state is to bind or subscribe to it. If you need to access it current value you can call `store.currentState()`.

### Middleware

Middleware is one of the coolest Amber's feature. It can react to any Event (Action and Transition) before or after it happens. More important Middleware can intersect events and delay or even cancel them until some conditions are met. Example will follow bul lets start with a simple example – logging all events. All middleware implementations should conform to AmberMiddleware protocol:

```Swift
public protocol AmberMiddleware{
    //Implement this function to process any event before it happens
    func process(state: Any, beforeEvent event: Any)
    
    //Implement this function to be able to delay or cancel any event before it will be directed to reducer
    func perform(event: Any, onState state: Any, route: AmberRoutePerformer, performBlock: @escaping () -> ())
    
    //Implement this function to process event or state after event was dispatched.
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer)
}
```
All this three functions have default implementations so in your Middleware you can implement only necessary ones. Logging Middleware will look as follows:
```Swift
class LoggingMiddleware: AmberMiddleware{
    func process(state: Any, afterEvent event: Any, route: AmberRoutePerformer){
        print("----------------------------------------")
        print("\(type(of: event)).\(event) -> \(state)")
    }
}
```
You register it as follows:
```Swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Amber.main.registerSharedMiddleware(LoggingMiddleware())
        /* other code... */
```
After that all app events will be printed in the console:
```
----------------------------------------
FeedAction.itemsLoaded([Paris, Flying man, Old Car]) -> isLoading: false, items: 3
----------------------------------------
FeedTransition.profile -> isLoading: false, items: 3
```
Lets consider more complicated case: our app has some actions that needs user confirmation before they can be performed. We could solve it in a such way:

```Swift
protocol ConfirmationRequirable{
    var needsConfirmation: Bool { get }
}

class ConfirmationMiddleware: AmberMiddleware{
    func perform(event: Any, route: AmberRoutePerformer, performBlock: @escaping () -> ()){
        //only if event that should occure is ConfirmationRequirable AND its needsConfirmation is true we proceed
        guard let crEvent = event as? ConfirmationRequirable, crEvent.needsConfirmation else{
            //otherwise we say that this action should be performed without any side affects
            //calling performBlock() invokes next Middleware to process this action or if it is the last registered Middleware, delivers this event to designated reducer/router
            performBlock()
            return
        }
        
        //we presents ConfirmationModule (popup)
        _ = route.present(ConfirmationModule) { a in
            //only if (and when) user confirmed this event we forwarding it
            if a == .confirmed { performBlock() }
        }
    }
}
```

After registering it `Amber.main.registerSharedMiddleware(LoggingMiddleware(), ConfirmationMiddleware())` and conforming any Event to `ConfirmationRequirable`:
```Swift
enum CartAction: AmberAction, ConfirmationRequirable{
    case clearCart, reload

    var needsConfirmation: Bool { return self == .clearCart }
}
```

From now on after Cart's store will recieve `.clearCart` action, `ConfirmationMiddleware` will take over and present a popup. If user would press "Confirm" then the action will be delivered to CartReducer otherwise it won't be dispatched. You can even implement `ConfirmationRequirable` protocol in transitions:
```Swift
enum ProfileTransition: AmberAction, ConfirmationRequirable{
    case history, logout

    var needsConfirmation: Bool { return self == .logout }
}
```

Using middlewares helps you to write less code and reuse logic between all modules. Other common cases of middlewares are: AnalyticsMiddleware (send events to your favorite analytics), NotificationMiddleware (notifies user that some event was performed), ServerMiddleware (performs server request), ErrorProcessing, Authorization (presents authorization screen for unauthorized users) and so on.

## App's first screen

You should set app's first screen in your `AppDelegate`:
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        Amber.setInitial(module: FeedModule, window: window)
```
and set to empty "Main Interface" field in your project settings (otherwise it will override your `Amber.setInitial` code). 

Of course you can set different initial screens based on any conditions:
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        if User.current.isAuthorized{
            Amber.setInitial(module: FeedModule, window: window)
        }else{
            Amber.setInitial(module: AuthorizationModule, window: window)
        }
```
## Transitions & module communications
### Types
All transitions and embeddings should be performed in routers. Inside your router's perform function you recieve `route` object which implements different ways of presenting/dismissing another modules.
You have three ways to present another module: 
* `replace`: replaces `UIApplication.shared.keyWindow?.rootViewController` with given module;
* `present`: presents new module;
* `show`: if current module contains navigationController, then pushes new module; otherwise presents it.

And four ways to exit from current screen:
* `dismiss`: dismisses current module;
* `pop`: pops to previous module in navigation controller;
* `popToRoot`: pops to first module in navigation controller's stack;
* `close`: if module is embedded then unembeds it; if module is in navigationController, then pops; othervise dismisses it.

For example:
```swift
class FeedRouter: AmberRouter{
    func perform(transition: FeedTransition,
                 route: AmberRoutePerformer,
                 reducer: FeedReducer,
                 performAction: @escaping (FeedAction) -> Void){
        switch transition {
        case .profile: _ = route.present(ProfileModule)
        case .showPhoto: _ = route.show(FeedItemModule)
        case .dismiss: route.close()
        }
    }
}
```

### Initial data
In Amber each module specifies directly what data is required for them to be presented. Other modules are forced to pass that data to them in order to present them. By default modules do not require any data:
```swift
struct ProfileState: AmberState {
    var description: String { return "ProfileState" }

    init(data: Void) { }
}
```
If module needs any data to be presented then you should replace `Void` in State's `init` with that data type:
```swift
struct ProfileState: AmberState {
    var description: String { return "ProfileState" }    
    let id: Int
    
    init(data: Int) { self.id = data }
}
```
After that other modules would be able to show Profile module only with requred data:
```swift
case .profile(let id): _ = route.present(ProfileModule, data: id)
```
The same is true for other types of presentation: show and replace.

### Embedding
Embedding is a special case of module presenting. What makes it different from any other presententations that it needs `UIView` object in which given module will be embedded:

```swift
class FeedItemRouter: AmberRouter{
     func perform(transition: FeedItemTransition,
                  route: AmberRoutePerformer,
                  reducer: FeedItemReducer,
                  performAction: @escaping (FeedItemAction) -> Void){
        switch transition {
        case .embedFilters(let view): _ = route.embed(FilterModule, inView: view)
        }
    }
}
```

### Communications between modules
Regardless of how another module was presented or even embedded, the communications between them are always working the same way. Lets call presenting module **Presenter** and presented module **Presented**. **Presented**is responsible for describing all the events it can produce (_PresentedOutputEvents_) and the events it can recieve (_PresentedInputEvents_). **Presenter** decides whether it be listening for _PresentedOutputEvents_ and can pass _PresentedInputEvents_ to _Presented_. It works as followings: 
In **Presenter**'s Reducer we declare **Presented**'s _PresentedInputEvents_ action block:

```swift
class FeedItemReducer: AmberReducer{    
    var filterInput: FilterReducer.InputActionListener? //It is equal to ((FilterInputAction) -> Void)?
```
It is a function that we can perform to pass _PresentedInputEvents_ to **Presented**. This function is returned to us by `route` object when we presenting/embedding another module:
```swift
        case .embedFilters(let view): 
            //this is how we pass this function to Reducer
            reducer.filterInput = route.embed(FilterModule, inView: view)
        }
```
If we are interested in _PresentedOutputEvents_ we can pass output listener block as extra argument:
```swift
        case .embedFilters(let view):
            reducer.filterInput = route.embed(FilterModule, inView: view) { outputEvent in
                switch outputEvent{
                case .updateImage(let image): performAction(.setImage(image))
                }
            }
        }
```

We process _PresentedInputEvents_ inside **Presented**'s Reducer `reduceInput` function:
```swift
class FilterReducer: AmberReducer{
    /* other code */
    func reduceInput(action: FilterInputAction, state: FilterState,
                     performAction: @escaping (FilterAction) -> Void,
                     performOutputAction: @escaping (FilterOutputAction) -> Void) -> FilterState{
        var newState = state
        switch action {
        case .reset:
            newState.saturation = 1
            newState.brightness = 0
            newState.contrast = 1
        }
        return newState
    }
```
And we can send _PresentedOutputEvents_ actions from three places:
* inside Reducer from `reduce` function via calling `performOutputAction(<OutputAction>)`;
* inside Reducer from `reduceInput` function via calling `performOutputAction(<OutputAction>)`;
* inside Controller by calling `store.performOutput(action: <OutputAction>)` or by binding to `outputAction` dynamic property.

## Amber module for generamba
Amber has its own [module](https://github.com/Anvics/AmberModule) for 
[Generamba](https://github.com/rambler-digital-solutions/Generamba) – so you won't write all this code by yourself.

## Example
You can check out simple example of Amber usage: [TestProject](https://github.com/Anvics/AmberExample)

## Installation

Amber is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Amber'
```

## Author

Nikita Arkhipov, nikitarkhipov@gmail.com
Anvics

## License

Amber is available under the MIT license. See the LICENSE file for more info.
