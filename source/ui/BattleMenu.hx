package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.text.FlxText;

import states.BattleState;
import utils.MapUtils;
import ui.BattleDialog;

class BattleMenu extends BattleDialog {

	//private static inline var lineHeight: Int = 14;
	private static inline var marginTop: Int = 0;
	//private static inline var marginTopText: Int = -3;
	private static inline var marginLeft: Int = 0;
	//private static inline var marginLeftArrow: Int = -10;
	//private static inline var marginTopArrow: Int = -2;
	//private static inline var marginLeftIcon: Int = 8;
	//private static inline var marginTopIcon: Int = 0;

	//private var selected: Int;
	//private var entries: Array<MenuEntry>;
	//private var arrow: FlxSprite;

	private var width: Int;
	private var height: Int;
	//private var rows: Int;

	//private var iconEnd: FlxSprite;

	public function new() {
		/*entries = new Array<MenuEntry>();

		var endTurnEntry = new MenuEntry();
		endTurnEntry.value = "end-turn";
		endTurnEntry.label = "End Turn";
		endTurnEntry.gfxPath = "assets/images/ui/icon-endturn-14.png";
		endTurnEntry.icon = new FlxSprite(x, y);
		endTurnEntry.icon.loadGraphic(endTurnEntry.gfxPath, false, 14, 14);
		endTurnEntry.text = new FlxText(x, y, endTurnEntry.label);

		entries.push(endTurnEntry);

		rows = entries.length;*/
		width = 3 * ViewPort.tileSize;
		height = 10 * ViewPort.tileSize;
		path = "assets/images/ui/sidebar-menu.png";

		super(width, height, marginTop, marginLeft, BattleDialog.QUADRANT_TOP_RIGHT);
		updateBackground();

		/*var index = 0;
		for (item in entries) {
			item.text.x = x + marginLeft;
			item.text.y = y + marginTop + marginTopText + index * lineHeight;
			item.text.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(item.text);

			item.icon.x = x + marginLeftIcon;
			item.icon.y = y + marginTop + marginTopIcon + index * lineHeight;
			add(item.icon);

			index++;
		}

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic("assets/images/ui/arrow.png", true, 18, 18);
		arrow.animation.add("default", [0, 1], 3, true);
		arrow.animation.play("default");
		add(arrow);

		highlight(0);
		visible = false;*/
	}

	override public function update(elapsed: Float) {
		if (covers(_map.cursor.pos.x, _map.cursor.pos.y)) {
			moveToQuadrant(BattleDialog.QUADRANT_TOP_LEFT);
		} else {
			restorePosition();
		}

		super.update(elapsed);
	}

	/*private function highlight(pos: Int) {
		if (pos >= 0 && pos < entries.length) {
			arrow.x = vpX + x + marginLeftArrow;
			arrow.y = vpY + y + marginTop + pos * lineHeight + marginTopArrow;
			selected = pos;
		}
	}

	public function nextItem() {
		var newPos = (selected + 1) % entries.length;
		highlight(newPos);
	}

	public function prevItem() {
		var newPos = selected - 1;
		if (newPos == -1)
			newPos = entries.length - 1;

		highlight(newPos);
	}

	public function select() {
		switch entries[selected].value {
			case "end-turn":
				_map.status = BattleState.STATUS_MAP_NAVIGATION;
				_map.onTurnEnd();
		}

		hide();
	}

	override public function show() {
		highlight(0);
		selected = 0;
		super.show();
	}

	override public function updateBackground() {
		if (background == null) {
			background = new FlxSprite(bgX, bgY);
			add(background);
		}

		var fullPath: String = path + Std.string(rows) + "_P" + Std.string(currentPlayer) + ".png";
		background.loadGraphic(fullPath, width, marginTop * 2 + lineHeight * rows);
	}*/
}
