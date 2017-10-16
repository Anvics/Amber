# Amber

[![Version](https://img.shields.io/cocoapods/v/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)
[![License](https://img.shields.io/cocoapods/l/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)
[![Platform](https://img.shields.io/cocoapods/p/Amber.svg?style=flat)](http://cocoapods.org/pods/Amber)

## Overview

Amber is flexible architecture based on Elm & Flux ideas and developed specifically for iOS. It separetes components of a module into six parts: 


**State**: is plain struct responsible for holding all data nased on which data is displayed.

**Actions**: are events that can happen in module: button press, data loaded, etc. 

**Reducer**: is class responsible for processing Actions and for initial setup.

**Transitions**: are types of transitions that can happen in module.

**Router**: is class responsible for processing Transitions

**Store**: holds reference to Reducer, Router and current State.

**View**: is plain mapping of the state into the user interface. It subscribes to current state and redraws itself accordingly to the new state. It also responsible for sending Actions and Transitions to the Store. 


## Benefits

## Where to use

## In depth overview

### State

### Actions

### Reducer

### Transition

### Router

### Store

### View

### Embedding

### Middleware

## Best practices

## Example

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
