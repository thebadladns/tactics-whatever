package;

import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;

import states.BattleState;

class Main extends Sprite {

	public function new() {
		super();
		addChild(new FlxGame(GameParams.WIDTH, GameParams.HEIGHT, BattleState, GameParams.ZOOM,
			GameParams.FRAME_RATE, GameParams.FRAME_RATE, true, false));
	}
}
