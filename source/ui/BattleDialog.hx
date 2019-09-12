package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

import states.MapState;
import states.BattleState;

import utils.Utils;
import utils.MapUtils;

class BattleDialog extends FlxTypedGroup<FlxSprite> {
	public static inline var QUADRANT_TOP_LEFT: Int = 0;
	public static inline var QUADRANT_TOP_RIGHT: Int = 1;
	public static inline var QUADRANT_BOTTOM_LEFT: Int = 2;
	public static inline var QUADRANT_BOTTOM_RIGHT: Int = 3;

	public static var bgColour: Array<Int> = [
		0xffe1d0,
		0xcce3ff
	];

	public static var bgAccentColour: Array<Int> = [
		0xf85800,
		0x1b78e9
	];

	public static inline var bgTileSize: Int = 8;

	public var bgWidth: Int;
	public var bgHeight: Int;
	public var x: Int;
	public var y: Int;
	public var originalX: Int;
	public var originalY: Int;
	public var vpX: Int;
	public var vpY: Int;
	public var bgX: Int;
	public var bgY: Int;

	private var currentPlayer: Int;

	public var quadrant: Int;
	public var background: FlxSprite;
	public var path: String;

	private var _map: BattleState;
	private var w: Int;
	private var h: Int;
	private var marginX: Int;
	private var marginY: Int;

	public function new(w: Int, h: Int, marginX: Int, marginY: Int, quadrant: Int) {
		super();

		_map = cast(FlxG.state, BattleState);

		currentPlayer = _map.getCurrentPlayer().id;

		bgWidth = w;
		bgHeight = h;

		this.marginX = marginX;
		this.marginY = marginY;
		this.quadrant = quadrant;

		vpX = 0;
		vpY = 0;
		x = 0;
		y = 0;
		bgX = 0;
		bgY = 0;

		moveToQuadrant(this.quadrant);

		originalX = x;
		originalY = y;
	}

	public function createBackground(width: Int, height: Int, colour: FlxColor) {
		background = new FlxSprite(bgX, bgY);
		background.makeGraphic(width, height, colour);
		add(background);
	}

	public function loadBackground(path: String, width: Int, height: Int) {
		if (background == null) {
			background = new FlxSprite(bgX, bgY);
			add(background);
		}

		updateBackground();
	}

	public function covers(posX: Float, posY: Float): Bool {
		var a1x = posX * ViewPort.tileSize;
		var a1y = posY * ViewPort.tileSize;
		var d1x = (posX + 1) * ViewPort.tileSize;
		var d1y = (posY + 1) * ViewPort.tileSize;

		var a2x = vpX + originalX;
		var a2y = vpY + originalY;
		var d2x = a2x + 2 * marginX + bgWidth;
		var d2y = a2y + 2 * marginY + bgHeight;

		var sx = Math.max(0, Math.min(d1x, d2x) - Math.max(a1x, a2x));
		var sy = Math.max(0, Math.min(d1y, d2y) - Math.max(a1y, a2y));

		return sx > 0 && sy > 0;
	}

	public function moveToQuadrant(quadrant: Int) {
		switch quadrant {
			case QUADRANT_TOP_LEFT:
				x = marginX;
				y = marginY;
			case QUADRANT_TOP_RIGHT:
				x = Std.int(ViewPort.width - bgWidth - marginX);
				y = marginY;
			case QUADRANT_BOTTOM_LEFT:
				x = marginX;
				y = Std.int(ViewPort.height - bgHeight - marginY);
			case QUADRANT_BOTTOM_RIGHT:
				x = Std.int(ViewPort.width - bgWidth - marginX);
				y = Std.int(ViewPort.height - bgHeight - marginY);
		}

		move(vpX + x, vpY + y);
	}

	public function move(x: Int, y: Int) {
		var offsetX = x - bgX;
		var offsetY = y - bgY;

		for (s in members) {
			s.x += offsetX;
			s.y += offsetY;
		}

		bgX = x;
		bgY = y;
	}

	public function setSize(w: Int, h: Int) {
		this.w = w;
		this.h = h;
	}

	public function restorePosition() {
		moveToQuadrant(quadrant);
	}

	public function setOffset(offsetX: Int, offsetY: Int) {
		vpX = offsetX;
		vpY = offsetY;
		move(vpX + x, vpY + y);
	}

	public function show() {
		var newCurrentPlayer: Int = _map.getCurrentPlayer().id;
		if (currentPlayer != newCurrentPlayer) {
			currentPlayer = newCurrentPlayer;
			updateBackground();
		}

		visible = true;
	}

	public function hide() {
		visible = false;
	}

	public function updateBackground() {
		if (background == null) {
			background = new FlxSprite(bgX, bgY);
			add(background);
		}

		//var fullPath: String = path + "_P" + Std.string(currentPlayer) + ".png";
		background.loadGraphic(path, bgWidth, bgHeight);
	}
}

class MenuEntry {
	public var label: String;
	public var value: String;
	public var gfxPath: String;
	public var icon: FlxSprite;
	public var text: FlxText;
	public var enabled: Bool;

	public function new() {
		enabled = true;
	}
}
