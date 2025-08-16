package scenes;

import entities.*;
import haxepunk.*;
import haxepunk.graphics.*;
import haxepunk.graphics.tile.*;
import haxepunk.input.*;
import haxepunk.masks.*;
import haxepunk.math.*;
import haxepunk.Tween;
import haxepunk.tweens.misc.*;
import haxepunk.utils.*;
import openfl.Assets;

class GameScene extends Scene
{
    public static inline var GAME_WIDTH = 320;
    public static inline var GAME_HEIGHT = 180;
    public static inline var NUMBER_OF_CHUNK_TYPES = 9;

    public var player(default, null):Player;
    private var curtain:Curtain;
    private var chunks:Array<Level>;

    override public function begin() {
        curtain = new Curtain();
        add(curtain);
        curtain.fadeOut(0.25);

        var start = new Level("start");
        add(start);
        for(entity in start.entities) {
            if(Type.getClass(entity) == Player) {
                player = cast(entity, Player);
            }
            add(entity);
        }
        chunks = [start];

        camera.x = player.centerX - GAME_WIDTH / 2;
    }

    override public function update() {
        if(player.centerX + GAME_WIDTH > getTotalChunkWidth()) {
            addChunk();
        }
        super.update();
        camera.x = player.centerX - GAME_WIDTH / 2;
        if(Key.pressed(Key.R)) {
            HXP.scene = new GameScene();
        }
    }

    private function getTotalChunkWidth() {
        var totalChunkWidth = 0;
        for(chunk in chunks) {
            totalChunkWidth += chunk.width;
        }
        return totalChunkWidth;
    }

    private function addChunk() {
        var chunk = new Level('${Random.randInt(NUMBER_OF_CHUNK_TYPES)}');
        chunk.x = getTotalChunkWidth();
        chunks.push(chunk);
        add(chunk);
        for(entity in chunk.entities) {
            entity.x += chunk.x;
            if(Type.getClass(entity) == MovingPlatform) {
                cast(entity, MovingPlatform).shiftPathPointsX(chunk.x);
            }
            add(entity);
        }
    }

    public function onDeath() {
        HXP.alarm(0.25, function() {
            curtain.fadeIn(0.25);
        });
        HXP.alarm(0.5, function() {
            HXP.scene = new GameScene();
        });
    }
}
