AngryBirdDemo
=============

AngryBirdDemo is a small game in the style of Angry Birds: you pull back a catapult and launch penguins at donuts to knock them off the screen. It runs on iOS devices and simulators, with simple touch controls, physics-based movement, sound effects, and a main menu screen to start playing.

Technically, this is a native iOS game written in Objective-C using SpriteKit, with level and scene layout authored visually in `.sks` files rather than in code. `GameScene` drives the core gameplay, wiring up the catapult with `SKPhysicsJointPin`/`SKPhysicsJointSpring`, handling touch-driven launches, and detecting collisions via `SKPhysicsContactDelegate`. Reusable prefabs (penguins, donuts) are wrapped by `ABReferenceNode` (an `SKReferenceNode` subclass), and simple UI buttons are implemented by `ABButtonNode`. The project has no CocoaPods/SPM dependencies or CLI build scripts — it's built and run directly from `AngryBirdDemo.xcodeproj` in Xcode.
