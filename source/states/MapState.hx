package states;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;

import entities.Unit;

import ui.BattleCursor;
import ui.BattleMenu;
//import ui.BattleDialog;
//import ui.TerrainBattleDialog;
//import ui.UnitBattleDialog;

import utils.Level;
import utils.MapUtils;
import utils.data.TilePoint;
import utils.Scene;

class MapState extends FlxTransitionableState {
	public var scene: Scene;
	public var players: Array<Player>;

	public var cursor: BattleCursor;
	public var menu: BattleMenu;

	public var level: Level;
	public var selectedUnit: Unit;

	override public function create() {
		super.create();
		scene = new Scene();

		level = new Level("assets/data/level-1.tmx");
		add(level.backgroundTiles);

		players = new Array<Player>();

		FlxG.camera.bgColor = FlxColor.WHITE;
		FlxG.camera.setSize(level.width * ViewPort.tileSize, level.height * ViewPort.tileSize);
	}

	public function moveViewport(x: Int, y: Int) {
		FlxG.camera.scroll.x = x;
		FlxG.camera.scroll.y = y;
	}

	public function onCursorChoose() {}

	public function calcUnitMovement(pos: TilePoint) {}

	public function getUnitsInAttackRange(unit: Unit): Array<Unit> {
		return null;
	}
}
