![](Assets/amberLogo2.png)
# Amber

![](https://img.shields.io/badge/Swift-4.0-orange.svg)
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

– makes application behavior more predictable;

– code stays good structured as your application grows;

– allow you to intercept all application events;

– easier to refactor and modify your code.

## Schema
![](Assets/overview.png)

## In depth overview

### State

State is a struct that stores all data needed for your module. For example:

```
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

Action is enum that holds all the actions that can happen inside a module. For example:

```
enum FeedAction: AmberAction{
    case itemsLoaded([FeedItem])
    case like(Int)
}
```

### Reducer

Reducer is a class that is mainly responsible for processing Actions. It takes as input a current state and an action which is occurred and should return new state.

```
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
Reduce function should be [pure function](https://en.wikipedia.org/wiki/Pure_function).

### Transition

### Router

### Store

### View




## Amber module for generamba
Here is [amber module](https://github.com/Anvics/AmberModule) for 
[Generamba](https://github.com/rambler-digital-solutions/Generamba)

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
