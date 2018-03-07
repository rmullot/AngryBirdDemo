//
//  MainMenuScene.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 06/03/2018.
//  Copyright © 2018 Apportable. All rights reserved.
//

#import "MainMenuScene.h"

@implementation MainMenuScene
/* UI Connections */

-(void) didMoveToView:(SKView *)view{
    
    /* Set UI connections */
    _buttonPlay = (ABButtonNode *)[self childNodeWithName:@"//buttonPlay"];
    
    /* Setup button selection handler */
    _buttonPlay.selectedHandler = ^void(void){
        if(self.view != nil){
            
            // Load the SKScene from 'GameScene.sks'
            SKScene *scene = [SKScene nodeWithFileNamed: @"MainMenuScene"];
            if(scene != nil){
                // Set the scale mode to scale to fit the window
                scene.scaleMode = SKSceneScaleModeAspectFit;
                
                // Present the scene
                [view presentScene:scene];
            }
            
            // Debug helpers
            view.showsFPS = true;
            view.showsPhysics = true;
            view.showsDrawCount = true;
        }
    };
    
}
@end
