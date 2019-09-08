package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;

import entities.Unit;
import states.MapState;

import utils.MapUtils;
import utils.Utils;
import utils.KeyboardUtils;
import utils.data.TilePoint;

class BattleCursor extends FlxSprite {
	public static inline var STATUS_HIDDEN: Int = 0;
	public static inline var STATUS_FREE: Int = 1;
	public static inline var STATUS_CHOOSE: Int = 2;

	private static inline var moveViewportThreshold: Int = 2;

	private static var marginTop: Int = -8;
	private static var marginTopOriginal: Int = -8;
	private static var marginTopInverted: Int = -20;
	private static var marginLeft: Int = -8;
	private static var marginLeftOriginal: Int = -8;
	private static var marginLeftInverted: Int = -20;

	public var _map: MapState;
	public var pos: TilePoint;
	public var hasMoved: Bool;
	public var frozen: Bool;
	public var status: Int;
	public var activeTiles: Array<TilePoint>;

	private var keyboard: KeyboardUtils;
	private var selectedTile: Int;

	public function new(posX: Int, posY: Int) {
		super(posX * ViewPort.tileSize + marginLeft, posY * ViewPort.tileSize + marginTop);
		loadGraphic("assets/images/ui/cursor.png", true, 60, 60);
		animation.add("idle", [0, 1], 2, true);
		deselect();

		_map = cast(FlxG.state, MapState);
		pos = new TilePoint(posX, posY);
		hasMoved = false;
		frozen = false;
		status = STATUS_FREE;

		selectedTile = 0;
		activeTiles = new Array<TilePoint>();

		keyboard = KeyboardUtils.getInstance();
	}

	override public function update(elapsed: Float) {
		var up: Bool = keyboard.isPressed(KeyboardUtils.KEY_UP);
		var down: Bool = keyboard.isPressed(KeyboardUtils.KEY_DOWN);
		var left: Bool = keyboard.isPressed(KeyboardUtils.KEY_LEFT);
		var right: Bool = keyboard.isPressed(KeyboardUtils.KEY_RIGHT);

		if (status == STATUS_FREE) {
			var newPos = new TilePoint(pos.x, pos.y);

			// Move the cursor
			if (up || down || left || right) {
				if (up && !down) {
					newPos.y = Utils.max(0, pos.y - 1);
				}

				if (down && !up) {
					newPos.y = Utils.min(_map.level.height - 1, pos.y + 1);
				}

				if (left && !right) {
					newPos.x = Utils.max(0, pos.x - 1);
				}

				if (right && !left) {
					newPos.x = Utils.min(_map.level.width - 1, pos.x + 1);
				}
			}

			hasMoved = newPos.x != pos.x || newPos.y != pos.y;

			// Determine if it's necessary to move the viewport
			if (hasMoved) {
				var moveViewport: Bool = false;
				var cameraPosX = Std.int(FlxG.camera.scroll.x / ViewPort.tileSize);
				var cameraPosY = Std.int(FlxG.camera.scroll.y / ViewPort.tileSize);

				// Moving right
				if (newPos.x != pos.x && newPos.x - cameraPosX >= (ViewPort.widthInTiles - moveViewportThreshold)) {
					cameraPosX = Utils.min(_map.level.width - ViewPort.widthInTiles, cameraPosX + 1);
					moveViewport = true;
				}

				// Moving left
				if (newPos.x != pos.x && newPos.x - cameraPosX < moveViewportThreshold) {
					cameraPosX = Utils.max(0, cameraPosX - 1);
					moveViewport = true;
				}

				// Moving down
				if (newPos.y != pos.y && newPos.y - cameraPosY >= (ViewPort.heightInTiles - moveViewportThreshold)) {
					cameraPosY = Utils.min(_map.level.height - ViewPort.heightInTiles, cameraPosY + 1);
					moveViewport = true;
				}

				// Moving up
				if (newPos.y != pos.y && newPos.y - cameraPosY < moveViewportThreshold) {
					cameraPosY = Utils.max(0, cameraPosY - 1);
					moveViewport = true;
				}

				if (moveViewport) {
					_map.moveViewport(cameraPosX * ViewPort.tileSize, cameraPosY * ViewPort.tileSize);
				}
			}

			// Calculate unit movement
			if (hasMoved)
				_map.calcUnitMovement(newPos);

			pos.x = newPos.x;
			pos.y = newPos.y;
			newPos = null;

			if (hasMoved)
				orientateCursor();
		}

		// Cursor movement over a set of available tiles
		if (status == STATUS_CHOOSE && activeTiles != null && activeTiles.length > 0) {
			if (up || right) {
				selectedTile = (selectedTile + 1) % activeTiles.length;
			}

			if (left || down) {
				selectedTile--;
				if (selectedTile == -1)
					selectedTile = activeTiles.length - 1;
			}

			pos.x = activeTiles[selectedTile].x;
			pos.y = activeTiles[selectedTile].y;

			if (up || down || left || right)
				_map.onCursorChoose();
		}

		x = pos.x * ViewPort.tileSize + marginLeft;
		y = pos.y * ViewPort.tileSize + marginTop;

		super.update(elapsed);
	}

	public function show(status: Int = STATUS_FREE) {
		frozen = false;
		visible = true;
		selectedTile = 0;
		this.status = status;
	}

	public function hide() {
		frozen = true;
		visible = false;
		status = STATUS_HIDDEN;
	}

	public function select() {
		animation.finish();
	}

	public function deselect() {
		animation.play("idle");
	}

	public function getSelectedActiveTile(): TilePoint {
		return activeTiles[selectedTile];
	}

	public function getSelectedTile(): Int {
		return selectedTile;
	}

	public function setActiveTiles(tiles: Array<TilePoint>) {
		Utils.clearPointArray(activeTiles);
		activeTiles = tiles;
	}

	public function orientateCursor() {
		var cameraPosX = Std.int(FlxG.camera.scroll.x / ViewPort.tileSize);
		var cameraPosY = Std.int(FlxG.camera.scroll.y / ViewPort.tileSize);

		// Disclaimer: assigning booleans in if clauses for the sake of readibility

		// Left
		if (pos.x - cameraPosX < moveViewportThreshold) {
			flipX = false;
			marginLeft = marginLeftOriginal;
		}

		// Right
		if (pos.x - cameraPosX >= (ViewPort.widthInTiles - moveViewportThreshold)) {
			flipX = true;
			marginLeft = marginLeftInverted;
		}
		// Up

		if (pos.y - cameraPosY < moveViewportThreshold) {
			flipY = false;
			marginTop = marginTopOriginal;
		}

		// Down
		if (pos.y - cameraPosY >= (ViewPort.heightInTiles - moveViewportThreshold)) {
			flipY = true;
			marginTop = marginTopInverted;
		}
	}

	public function getQuadrant(): Int {
		var cameraPosX: Int = Std.int(FlxG.camera.scroll.x / ViewPort.tileSize);
		var cameraPosY: Int = Std.int(FlxG.camera.scroll.y / ViewPort.tileSize);

		var vpPosX: Int = pos.x - cameraPosX;
		var vpPosY: Int = pos.y - cameraPosY;

		var quadrant: Int = 0;

		if (vpPosX > (ViewPort.widthInTiles / 2)) quadrant += 1;
		if (vpPosY >= (ViewPort.heightInTiles / 2)) quadrant += 2;

		return quadrant;
	}
}
