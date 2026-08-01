//
//  MainMenuScene.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 06/03/2018.
//  Copyright © 2018 Apportable. All rights reserved.
//

#import "MainMenuScene.h"

@interface MainMenuScene () {
    CGSize _backgroundOriginalSize;
}
@end

@implementation MainMenuScene
/* UI Connections */

-(void) didMoveToView:(SKView *)view{

    /* Set UI connections */
    _buttonPlay = (ABButtonNode *)[self childNodeWithName:@"//buttonPlay"];

    /* The background sprite isn't named in MainMenuScene.sks, so pick it out
       as the sprite child that isn't the play button. */
    for (SKNode *child in self.children) {
        if ([child isKindOfClass:[SKSpriteNode class]] && ![child isKindOfClass:[ABButtonNode class]]) {
            self.background = (SKSpriteNode *)child;
            break;
        }
    }
    _backgroundOriginalSize = self.background.size;
    [self resizeBackgroundToFillScreen];

    /* Setup button selection handler */
    _buttonPlay.selectedHandler = ^void(void){
        if(self.view != nil){
            
            // Load the SKScene from 'GameScene.sks'
            SKScene *scene = [SKScene nodeWithFileNamed: @"GameScene"];
            if(scene != nil){
                // Resize the scene to match the actual screen size, so its
                // coordinate system (camera bounds, node positions) reflects
                // the real device size instead of a fixed design canvas.
                scene.scaleMode = SKSceneScaleModeResizeFill;
                
                // Present the scene
                [view presentScene:scene];
            }
            
            // Debug helpers
            view.showsFPS = NO;
            view.showsPhysics = NO;
            view.showsDrawCount = NO;
        }
    };

}

- (void)didChangeSize:(CGSize)oldSize {
    [super didChangeSize:oldSize];
    [self resizeBackgroundToFillScreen];
}

/* Scale the (static) menu background to cover the full viewport on devices
   bigger than the design canvas it was authored for, cropping any overflow
   instead of stretching/distorting the artwork. */
- (void)resizeBackgroundToFillScreen {
    if (self.background == nil || CGSizeEqualToSize(_backgroundOriginalSize, CGSizeZero)) {
        return;
    }
    CGFloat scale = MAX(self.size.width / _backgroundOriginalSize.width, self.size.height / _backgroundOriginalSize.height);
    self.background.size = CGSizeMake(_backgroundOriginalSize.width * scale, _backgroundOriginalSize.height * scale);
}

@end
