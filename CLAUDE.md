# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

AngryBirdDemo is an iOS game built with Objective-C and SpriteKit (originally scaffolded from an Apportable/Cocos2D template, since migrated to native SpriteKit). Scene layout and physics for levels/nodes are authored visually with Xcode's SpriteKit scene editor (`.sks` files) rather than in code, and SpriteBuilder (`AngryBirdDemo.spritebuilder`) was used historically for some assets.

## Build & run

Open `AngryBirdDemo.xcodeproj` in Xcode and build/run the `AngryBirdDemo` scheme on an iOS simulator or device. There is no CLI build script, package manager, or test target in this repo — it's a plain Xcode project with no CocoaPods/SPM dependencies.

## Architecture

- **Scenes are split between visual (`.sks`) and code (`.h`/`.m`) halves.** Each `SKScene` subclass (`GameScene`, `MainMenuScene`) wires itself up in `didMoveToView:` by looking up child nodes placed in the corresponding `.sks` file by name (`childNodeWithName:`), rather than constructing the node tree in code. When editing scene behavior, expect to open both the `.m` file and the matching `.sks` file (e.g. `GameScene.m` + `Scenes/GameScene.sks`, level layout in `Level1.sks`).
- **`GameScene`** (`GameScene.h/.m`) is the core gameplay scene: it wires up the catapult (`catapultArm`, `catapult`, `cantileverNode`) via `SKPhysicsJointPin`/`SKPhysicsJointSpring`, handles touch-driven launching of penguins in `touchesBegan:`/`touchesMoved:`/`touchesEnded:`, tracks the active projectile with a camera-follow in `update:`, and implements `SKPhysicsContactDelegate` (`didBeginContact:`) to detect penguin/donut collisions and trigger donut death (particle effect + SFX, in `dieDonut:`).
- **`ABReferenceNode`** (subclass of `SKReferenceNode`) wraps reusable `.sks`-authored prefabs (e.g. `Scenes/Penguin.sks`, `Scenes/Donut.sks`) and exposes an `avatar` property pointing at the root sprite, so gameplay code can position/physics-configure the instantiated prefab without knowing its internal node structure.
- **`ABButtonNode`** (subclass of `SKSpriteNode`) implements a simple tappable button with `active`/`selected`/`hidden` states (`ABButtonNodeState`) and a `selectedHandler` block callback; used for in-scene UI like the restart button in `GameScene` and the play button in `MainMenuScene`.
- **Physics category bit masks** (defined per-node in the `.sks` files, not in code) distinguish collidable types — e.g. category `2` is used for donuts in `GameScene`'s contact handling.
- **Effects & audio**: particle effects live in `Effects/*.sks` (e.g. `DonutExplosion.sks`), sound effects in `SFX/*.caf`, played via `SKAction playSoundFileNamed:`.
- **App entry point** is the standard iOS `Source/AppDelegate.m` / `Source/main.m`; storyboards in `Source/Resources/` (`Main.storyboard`, `LaunchScreen.storyboard`) set up the initial `GameViewController`, which presents the SpriteKit scenes.
