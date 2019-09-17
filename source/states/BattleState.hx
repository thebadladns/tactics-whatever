package states;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.system.scaleModes.PixelPerfectScaleMode;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import openfl.Assets;
import haxe.Timer;

import states.MapState;

import entities.Unit;
//import entities.Transport;
//import entities.Infantry;

//import ui.BattleDialog;
import ui.BattleCursor;
import ui.BattleMenu;
//import ui.ActionBattleDialog;
//import ui.UnitInfoDialog;
//import ui.UnitDeploymentDialog;
//import ui.TerrainBattleDialog;
//import ui.UnitBattleDialog;
//import ui.COBattleDialog;

import utils.MapUtils;
import utils.Utils;
import utils.KeyboardUtils;
import utils.data.TilePoint;
import utils.data.Set;
import utils.Level;

//import entities.Building;
//import entities.BuildingBase;

class BattleState extends MapState {
	public static var STATUS_MENU = 0;
	public static var STATUS_MAP_NAVIGATION = 1;
	public static var STATUS_UNIT_DEPLOYMENT = 2;
	public static var STATUS_UNIT_INFO = 3;
	public static var STATUS_ATTACK_RANGE = 4;

	public static var fundsPerProperty: Int = 1000;
	public static var maxFunds: Int = 999999;

	//public var buildings: Map<Int, Building>;

	public var armyIterator: Iterator<Unit>;	// iterator on current army's units

	/*public var unitInfo: UnitBattleDialog;
	public var terrainInfo: TerrainBattleDialog;
	public var unitInfoDialog: UnitInfoDialog;
	public var unitDeploymentDialog: UnitDeploymentDialog;
	public var actionDialog: ActionBattleDialog;
	public var coDialog: COBattleDialog;*/

	public var turn: Int;
	public var currentPlayer: Int;
	public var status: Int;

	public var pathArrow: FlxTypedGroup<FlxSprite>;
	public var movementRange: FlxTypedGroup<FlxSprite>;
	public var attackRange: FlxTypedGroup<FlxSprite>;
	public var pathOptions: utils.PathOptions;
	public var activePath: Path;
	public var tilesInAttackRange: Set<TilePoint>;
	public var unitsInAttackRange: Array<Unit>;

	private var prevPos: TilePoint;
	private var keyboard: KeyboardUtils;

	private static var instance: BattleState;

	override public function create() {
		super.create();
		instance = this;

		transIn = new TransitionData(TransitionType.TILES, FlxColor.BLACK, 1.0);
		transOut = new TransitionData(TransitionType.TILES, FlxColor.BLACK, 1.0);
		FlxG.scaleMode = new PixelPerfectScaleMode();

		turn = 1;
		currentPlayer = 0;
		status = STATUS_MAP_NAVIGATION;
		prevPos = new TilePoint(0, 0);
		keyboard = KeyboardUtils.getInstance();

		level = new Level("assets/data/level-1.tmx");

		scene.addLayer("map");
		scene.getLayer("map").add(level.backgroundTiles);

		FlxG.camera.bgColor = FlxColor.WHITE;
		FlxG.camera.setSize(Std.int(level.width * ViewPort.tileSize), Std.int(level.height * ViewPort.tileSize));

		/*scene.addLayer("buildings");
		buildings = new Map<Int, Building>();
		for (building in level.buildings) {
			buildings.set(MapUtils.coordsToIndex(building.posX, building.posY), building);
			scene.getLayer("buildings").add(building);
		}*/

		movementRange = new FlxTypedGroup<FlxSprite>();

		scene.addLayer("unitRange");
		scene.getLayer("unitRange").add(movementRange);

		attackRange = new FlxTypedGroup<FlxSprite>();
		scene.getLayer("unitRange").add(attackRange);

		loadPlayers();

		scene.addLayer("units");
		for (unit in level.units) {
			players[unit.player].army.push(unit);
			scene.getLayer("units").add(unit);
		}

		scene.addLayer("movement");
		pathArrow = new FlxTypedGroup<FlxSprite>();
		scene.getLayer("movement").add(pathArrow);

		scene.addLayer("activeUnit");

		scene.addLayer("hud");

		cursor = new BattleCursor(6, 4);
		scene.getLayer("hud").add(cursor);

		/*unitInfounitInfo = new UnitBattleDialog(BattleDialog.QUADRANT_BOTTOM_RIGHT);
		unitInfo.hide();
		scene.getLayer("hud").add(unitInfo);*/

		/*terrainInfo = new TerrainBattleDialog(BattleDialog.QUADRANT_BOTTOM_RIGHT);
		scene.getLayer("hud").add(terrainInfo);*/

		/*actionDialog = new ActionBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT);
		actionDialog.disableEntry("load");
		scene.getLayer("hud").add(actionDialog);*/

		/*coDialog = new COBattleDialog();
		coDialog.refresh();
		scene.getLayer("hud").add(coDialog);*/

		/*unitInfoDialog = new UnitInfoDialog();
		scene.getLayer("hud").add(unitInfoDialog);*/

		/*unitDeploymentDialog = new UnitDeploymentDialog();
		scene.getLayer("hud").add(unitDeploymentDialog);*/

		/*combatDialog = new CombatBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT);
		scene.getLayer("hud").add(combatDialog);*/

		menu = new BattleMenu();
		scene.getLayer("hud").add(menu);

		/*battleHud = new BattleHud();
		scene.getLayer("hud").add(battleHud);*/

		cursorOnFirstUnit();

		scene.update(this);
	}

	override public function update(elapsed: Float) {
		// Select or open menu
		if (FlxG.keys.justPressed.Z) {
			onSelect(cursor.pos.x, cursor.pos.y);
		}

		// Cancel current selection
		if (FlxG.keys.justPressed.X) {
			onCancel();
		}

		// Hides attack range if it was shown
		if (FlxG.keys.justReleased.X) {
			if (selectedUnit == null && status == STATUS_ATTACK_RANGE) {
				status = STATUS_MAP_NAVIGATION;
				Utils.clearSpriteGroup(attackRange);
			}
		}

		// Select next available unit
		if (FlxG.keys.justPressed.A) {
			onNextUnit();
		}

		// Move the cursor in dialogs
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) {
			onDialogNavigate(FlxG.keys.justPressed.UP);
		}

		keyboard.update(elapsed);
		super.update(elapsed);
	}

	public static function getInstance(): BattleState {
		return instance;
	}

	override public function moveViewport(x: Float, y: Float) {
		var offsetX = Std.int(x - FlxG.camera.scroll.x);
		var offsetY = Std.int(y - FlxG.camera.scroll.y);

		menu.setOffset(Std.int(x), Std.int(y));

		/*unitInfo.setOffset(x, y);
		terrainInfo.setOffset(x, y);
		actionDialog.setOffset(x, y);
		unitInfoDialog.setOffset(x, y);
		unitDeploymentDialog.setOffset(x, y);*/
		//combatDialog.setOffset(x, y);

		FlxG.camera.scroll.x = x;
		FlxG.camera.scroll.y = y;
	}

	public function centerCamera(posX: Int, posY: Int) {
		var cameraPosX: Int = posX - Std.int(ViewPort.widthInTiles / 2);
		var cameraPosY: Int = posY - Std.int(ViewPort.heightInTiles / 2);

		cameraPosX = Utils.min(Std.int(level.width - ViewPort.widthInTiles), Utils.max(0, cameraPosX));
		cameraPosY = Utils.min(Std.int(level.height - ViewPort.heightInTiles), Utils.max(0, cameraPosY));

		moveViewport(Std.int(cameraPosX * ViewPort.tileSize), Std.int(cameraPosY * ViewPort.tileSize));
	}

	public function centerCameraOnCursor() {
		centerCamera(cursor.pos.x, cursor.pos.y);

		prevPos.x = cursor.pos.x;
		prevPos.y = cursor.pos.y;
	}

	/* ------------------------------------ onSelect ----------------------------------- */

	public function onSelect(posX: Int, posY: Int) {
		if (selectedUnit == null) {
			prevPos.x = cursor.pos.x;
			prevPos.y = cursor.pos.y;
		}

		var selected = onSelectDestination(posX, posY);
		if (!selected) selected = onSelectAction();
		if (!selected) selected = onSelectTarget();
		if (!selected) selected = onSelectUnit(posX, posY);
		//if (!selected) selected = onSelectBuilding(posX, posY);
		if (!selected) selected = onSelectEmptyTile(posX, posY);
		if (!selected) selected = onSelectMenuEntry();
		if (!selected) selected = onSelectUnitForDeployment();
	}

	public function onSelectDestination(posX: Int, posY: Int): Bool {
		var index = MapUtils.coordsToIndex(posX, posY);

		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_SELECTED &&
			isTileFree(posX, posY) && pathOptions.nodes.contains(new TilePoint(posX, posY))) {

			Utils.clearSpriteGroup(pathArrow);
			Utils.clearSpriteGroup(movementRange);
			Utils.clearSpriteGroup(attackRange);

			prevPos.x = selectedUnit.pos.x;
			prevPos.y = selectedUnit.pos.y;

			pathOptions.chosenPath = pathOptions.bestPaths.get(index);
			selectedUnit.moveUnit(posX, posY, pathOptions.chosenPath, onMoveEnd);

			return true;
		}

		return false;
	}

	public function onSelectAction(): Bool {
		/*if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {

			// If unit has moved and was capturing, stop the current capture process
			if (selectedUnit.canCapture() && cast(selectedUnit, Infantry).isCapturing && (prevPos.x != selectedUnit.pos.x || prevPos.y != selectedUnit.pos.y)) {
				cast(selectedUnit, Infantry).stopCapture();
			}

			var action: String = actionDialog.select();
			switch action {
				case "attack":
					selectedUnit.status = UnitStatus.STATUS_ATTACK_READY;

					var targets: Array<TilePoint> = new Array<TilePoint>();
					for (unit in selectedUnit.canAttack(unitsInAttackRange)) {
						targets.push(unit.pos);
					}

					cursor.setActiveTiles(targets);
					cursor.show(BattleCursor.STATUS_CHOOSE);
					actionDialog.hide();

					unitInfo.setUnit(MapUtils.getUnitInTile(this, MapUtils.pointToIndex(cursor.getSelectedActiveTile())));
					unitInfo.showDamageDialog();
					unitInfo.show();
					terrainInfo.show();

				case "capture":
					cast(selectedUnit, Infantry).capture(buildings.get(MapUtils.coordsToIndex(selectedUnit.pos.x, selectedUnit.pos.y)));
					onWait();

				case "wait":
					onWait();

				case "Items":
					selectedUnit.status = UnitStatus.STATUS_ON_INVENTORY;
					actionDialog.hide();

				case "load":
					var transport: Transport = isCompatibleTransport(selectedUnit, selectedUnit.pos.x, selectedUnit.pos.y);
					if (transport != null) {
						actionDialog.hide();

						selectedUnit.status = UnitStatus.STATUS_LOADED;
						transport.load(selectedUnit);
						scene.moveEntity(selectedUnit.ID, "activeUnit", "units");
						selectedUnit = null;

						cursor.show();
						terrainInfo.show();
						unitInfo.show();
						coDialog.show();
					}

				case "unload":
					// If more than one unit can be unloaded, insert an intermediate step for choosing the unit to unload
					var selectedTransport: Transport = cast(selectedUnit, Transport);
					var unloadableUnits: Set<Int> = selectedTransport.getUnloadableUnits();
					if (!unloadableUnits.isEmpty()) {
						actionDialog.hide();

						cursor.setActiveTiles(selectedTransport.getTilesToUnload(unloadableUnits.toArray()[0]));
						cursor.show(BattleCursor.STATUS_CHOOSE);
						selectedTransport.status = UnitStatus.STATUS_UNLOADING;
					}
			}

			return true;
		}*/

		return false;
	}

	public function onSelectTarget(): Bool {
		/*if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			selectedUnit.status = UnitStatus.STATUS_ATTACKING;
			Utils.clearSpriteGroup(attackRange);

			onAttack(function() {
				cursor.show();
				//battleHud.hide();
				onWait();
			});

			return true;
		}
		else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_UNLOADING) {
			var tile: TilePoint = cursor.getSelectedActiveTile();
			var selectedTransport: Transport = cast(selectedUnit, Transport);

			selectedTransport.unload(selectedTransport.getUnloadableUnits().toArray()[0], tile.x, tile.y);
			onWait();

			return true;
		}*/

		return false;
	}

	public function onSelectUnit(posX: Int, posY: Int): Bool {
		var index = MapUtils.coordsToIndex(posX, posY);
		var units: Array<Unit> = getCurrentPlayer().getUnitsInTile(index);
		var unit: Unit = null;

		var found: Bool = false;
		var i: Int = 0;
		while (!found && i < units.length) {
			found = units[i].status == UnitStatus.STATUS_AVAILABLE;
			if (found) unit = units[i];
			i++;
		}

		if (selectedUnit == null && unit != null /*&& !menu.visible*/) {
			if (unit.select()) {
				selectedUnit = unit;
				/*terrainInfo.hide();
				unitInfo.hide();
				coDialog.hide();*/

				cursor.select();
				drawMovementRange();

				if (activePath != null) {
					activePath.destroy();
					activePath.add(new TilePoint(selectedUnit.pos.x, selectedUnit.pos.y));
				}

				scene.moveEntity(selectedUnit.ID, "units", "activeUnit");
				scene.update(this);
			} else {
				cursor.hide();
				//menu.show();
			}

			return true;
		}

		return false;
	}

	/*public function onSelectBuilding(posX: Int, posY: Int): Bool {
		var index = MapUtils.coordsToIndex(posX, posY);
		var building = buildings.get(index);

		if (selectedUnit == null && status == STATUS_MAP_NAVIGATION && building != null &&
			building.belongsTo == currentPlayer && building.getBuildingType() != 'hq' &&
			building.getBuildingType() != 'city') {

			prevPos.x = posX;
			prevPos.y = posY;
			building.onSelect();

			return true;
		}

		return false;
	}*/

	public function onSelectEmptyTile(posX: Int, posY: Int): Bool {
		var index = MapUtils.coordsToIndex(posX, posY);

		/*if (selectedUnit == null && status == STATUS_MAP_NAVIGATION && !menu.visible &&
			!getCurrentPlayer().army.exists(index) && !buildings.exists(index)) {
			
			status = STATUS_MENU;
			cursor.hide();
			menu.show();

			return true;
		}*/

		return false;
	}

	public function onSelectMenuEntry(): Bool {
		/*if (status == STATUS_MENU && menu.visible) {
			menu.select();
			cursor.show(BattleCursor.STATUS_FREE);

			return true;
		}*/

		return false;
	}

	public function onSelectUnitForDeployment(): Bool {
		/*if (status == STATUS_UNIT_DEPLOYMENT && unitDeploymentDialog.visible) {
			unitDeploymentDialog.deploy();

			return true;
		}*/

		return false;
	}

	/* ------------------------------------ onCancel ----------------------------------- */

	public function onCancel() {
		onCheckingAttackRange();
		onCancelUnitSelected();
		onCancelUnitMoved();
		onCancelSelectTarget();
		//onCancelItemSelection();
		//onCancelBuildingSelection();
		onCancelMenu();
	}

	public function onCheckingAttackRange() {
		var unit: Unit = MapUtils.getUnitInTile(this, MapUtils.coordsToIndex(cursor.pos.x, cursor.pos.y));

		if (selectedUnit == null && status == STATUS_MAP_NAVIGATION && unit != null) {
			status = STATUS_ATTACK_RANGE;
			var pos: utils.PathOptions = MapUtils.findPathOptions(this, unit);
			getAttackRange(unit, pos.nodes);
			drawAttackRange();
		}
	}

	public function onCancelUnitSelected() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_SELECTED) {
			pathOptions.destroy();
			Utils.clearSpriteGroup(movementRange);
			Utils.clearSpriteGroup(pathArrow);
			Utils.clearSpriteGroup(attackRange);

			cursor.deselect();
			cursor.pos.x = prevPos.x;
			cursor.pos.y = prevPos.y;
			centerCameraOnCursor();

			scene.moveEntity(selectedUnit.ID, "activeUnit", "units");
			scene.update(this);

			selectedUnit.deselect();
			selectedUnit = null;

			syncIdleAnimations();

			/*terrainInfo.show();
			unitInfo.show();
			coDialog.show();*/
		}
	}

	public function onCancelUnitMoved() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			Utils.clearSpriteGroup(pathArrow);
			Utils.clearSpriteGroup(attackRange);

			cursor.pos.x = prevPos.x;
			cursor.pos.y = prevPos.y;
			selectedUnit.moveUnit(prevPos.x, prevPos.y, null);
			selectedUnit.select();

			drawMovementRange();

			cursor.show(BattleCursor.STATUS_FREE);
			//actionDialog.hide();
		}
	}

	public function onCancelSelectTarget() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			Utils.clearPointArray(cursor.activeTiles);
			Utils.clearSpriteGroup(attackRange);

			/*terrainInfo.hide();
			unitInfo.hideDamageDialog();
			unitInfo.hide();*/
			cursor.hide();
			/*actionDialog.show();

			unitInfo.setUnit(selectedUnit);*/
			//combatDialog.hide();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		}
		else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_LOADING) {
			cursor.hide();
			//actionDialog.show();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		}
		else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_UNLOADING) {
			cursor.hide();
			//actionDialog.show();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		}
	}

	/*public function onCancelItemSelection() {
		if (selectedUnit != null && (selectedUnit.status == UnitStatus.STATUS_ON_INVENTORY ||
			selectedUnit.status == UnitStatus.STATUS_ON_SELECT_WEAPON)) {

			updateAttackRange();
			if (unitsInAttackRange.length > 0 && selectedUnit.canAttack(unitsInAttackRange).length > 0)
				actionDialog.enableEntry("attack");
			else
				actionDialog.disableEntry("attack");

			actionDialog.show();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		}
	}*/

	/*public function onCancelBuildingSelection() {
		var index = MapUtils.coordsToIndex(prevPos.x, prevPos.y);

		if (status == STATUS_UNIT_DEPLOYMENT && buildings.exists(index)) {
			status = STATUS_MAP_NAVIGATION;
			buildings.get(index).onCancel();
		}
	}*/

	public function onCancelMenu() {
		/*if (status == STATUS_MENU && menu.visible) {
			status = STATUS_MAP_NAVIGATION;
			menu.hide();
			cursor.show(BattleCursor.STATUS_FREE);
		}*/
	}

	public function onAttack(callback: Void -> Void) {
		//var defUnit = findEnemyUnit(MapUtils.pointToIndex(cursor.getSelectedActiveTile()));

		//trace("Attacking this guy: " + cursor.getSelectedActiveTile());

		//combatDialog.hide();
		cursor.hide();
		/*battleHud.setUnits(selectedUnit, defUnit);
		battleHud.show();*/

		/*selectedUnit.attack(defUnit, function() {
			Utils.clearSpriteGroup(attackRange);
			Utils.clearPointArray(cursor.activeTiles);

			cursor.pos.x = selectedUnit.pos.x;
			cursor.pos.y = selectedUnit.pos.y;

			if (!defUnit.isAlive()) {
				onDeath(defUnit, players[defUnit.player].army);
			} else if (!selectedUnit.isAlive()) {
				onDeath(selectedUnit, getCurrentPlayer().army);
				selectedUnit = null;
			}

			Timer.delay(callback, 600);
		});*/

		callback();
	}

	public function onWait() {
		var oldTile: Int = MapUtils.coordsToIndex(prevPos.x, prevPos.y);

		pathOptions.destroy();
		pathOptions = null;

		Utils.clearSpriteGroup(movementRange);
		Utils.clearSpriteGroup(pathArrow);
		Utils.clearSpriteGroup(attackRange);

		cursor.deselect();
		cursor.show(BattleCursor.STATUS_FREE);
		/*actionDialog.hide();
		terrainInfo.show();
		unitInfo.hideDamageDialog();
		unitInfo.show();
		coDialog.show();*/

		scene.moveEntity(selectedUnit.ID, "activeUnit", "units");


		var newTile: Int = MapUtils.coordsToIndex(selectedUnit.pos.x, selectedUnit.pos.y);
		selectedUnit.defenseBonus = MapUtils.getTerrainDefenseBonus(this, newTile);
		selectedUnit.avoidBonus = MapUtils.getTerrainAvoidBonus(this, newTile);
		selectedUnit.onWait();
		selectedUnit = null;

		syncIdleAnimations();
	}

	public function onDeath(unit: Unit, army: Array<Unit>) {
		unit.die(function() {
			army.remove(unit);
			unit.destroy();
		});
	}

	public function onDialogNavigate(goingUp: Bool) {
		/*if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			if (goingUp)
				actionDialog.prevItem();
			else
				actionDialog.nextItem();
		}

		if (menu.visible) {
			if (goingUp)
				menu.prevItem();
			else
				menu.nextItem();
		}*/
	}

	override public function onCursorChoose() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			//combatDialog.defUnit = unitsInAttackRange[cursor.getSelectedTile()];
			//combatDialog.refresh();
			//unitInfo.setUnit(MapUtils.getUnitInTile(this, MapUtils.pointToIndex(cursor.getSelectedActiveTile())));
		}
	}

	override public function calcUnitMovement(pos: TilePoint) {
		if (selectedUnit != null && pathOptions != null) {

			if (activePath == null) {
				activePath = new Path();
				activePath.add(new TilePoint(selectedUnit.pos.x, selectedUnit.pos.y));
			}

			if (activePath.containsInt(pos.x, pos.y)) {
				activePath.removeFrom(pos);
			} else {
				activePath.add(pos);
			}

			/*trace("activePath = " + activePath.toString());
			trace("pathMap = " + pathOptions.pathMap);*/

			var selectedPath: Path = null;
			if (pathOptions.pathMap.exists(activePath.toString())) {
				selectedPath = pathOptions.pathMap.get(activePath.toString());
			} else {
				selectedPath = pathOptions.bestPaths.get(MapUtils.pointToIndex(pos));
			}

			//trace("selectedPath = " + selectedPath);

			MapUtils.drawPath(selectedPath, this);
		}
	}

	public function onMoveEnd(path: FlxPath) {
		selectedUnit.moveElems(selectedUnit.pos.x, selectedUnit.pos.y);
		selectedUnit.status = UnitStatus.STATUS_MOVED;
		updateAttackRange();

		/*if (unitsInAttackRange.length > 0 && selectedUnit.canAttack(unitsInAttackRange).length > 0 && (
			selectedUnit.atkRangeMax == 1 || pathOptions.chosenPath.cost == 0		// Either it's a direct combat unit, or it's an indirect combat unit and it hasn't moved
		))
			actionDialog.enableEntry("attack");
		else
			actionDialog.disableEntry("attack");

		if (selectedUnit.atkRangeMax > 1 && pathOptions.chosenPath.cost == 0 && selectedUnit.canAttack(unitsInAttackRange).length == 0) {
			actionDialog.enableEntry("no-attack");
		} else {
			actionDialog.disableEntry("no-attack");
		}*/

		/*var index = MapUtils.coordsToIndex(selectedUnit.pos.x, selectedUnit.pos.y);
		if (buildings.exists(index) && buildings.get(index).belongsTo != getCurrentPlayer().id && selectedUnit.canCapture())
			actionDialog.enableEntry("capture");
		else
			actionDialog.disableEntry("capture");*/

		/*if (isCompatibleTransport(selectedUnit, selectedUnit.pos.x, selectedUnit.pos.y) != null) {
			actionDialog.enableEntry("load");
			actionDialog.disableEntry("wait");
			actionDialog.disableEntry("capture");
		} else {
			actionDialog.disableEntry("load");
			actionDialog.enableEntry("wait");
		}

		if (selectedUnit.isTransport() && !cast(selectedUnit, Transport).getUnloadableUnits().isEmpty()) {
			actionDialog.enableEntry("unload");
		} else {
			actionDialog.disableEntry("unload");
		}

		actionDialog.show();*/
		cursor.hide();
	}

	public function onNextUnit() {
		var unit: Unit = null;
		if (getCurrentPlayer().getTotalActiveUnits() > 0) {
			while (unit == null || unit.status != UnitStatus.STATUS_AVAILABLE) {
				unit = getNextUnitInArmy();
			}

			if (unit != null) {
				cursor.pos.x = unit.pos.x;
				cursor.pos.y = unit.pos.y;
				centerCameraOnCursor();
			}
		}
	}

	public function drawMovementRange() {
		Utils.clearSpriteGroup(movementRange);

		pathOptions = MapUtils.findPathOptions(this, selectedUnit);
		for (tile in pathOptions.nodes.getAll()) {
			var tileGraphic = new FlxSprite(tile.x * ViewPort.tileSize, tile.y * ViewPort.tileSize);
			tileGraphic.loadGraphic("assets/images/area-tiles-blue.png", true, Std.int(ViewPort.tileSize), Std.int(ViewPort.tileSize));

			var neighbour: TilePoint = new TilePoint(tile.x, tile.y - 1);
			var hasTileUp: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.y = tile.y + 1;
			var hasTileDown: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.x = tile.x - 1;
			neighbour.y = tile.y;
			var hasTileLeft: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.x = tile.x + 1;
			var hasTileRight: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));

			var frameIndex: Int = 0;
			frameIndex |= hasTileRight;
			frameIndex |= hasTileLeft << 1;
			frameIndex |= hasTileDown << 2;
			frameIndex |= hasTileUp << 3;

			tileGraphic.animation.frameIndex = frameIndex;
			tileGraphic.alpha = 0.6;
			movementRange.add(tileGraphic);
		}
	}

	public function drawAttackRange() {
		Utils.clearSpriteGroup(attackRange);

		for (tile in tilesInAttackRange.getAll()) {
			var tileGraphic = new FlxSprite(tile.x * 16, tile.y * 16);
			tileGraphic.loadGraphic("assets/images/area-tiles-red.png", true, 16, 16);

			var neighbour: TilePoint = new TilePoint(tile.x, tile.y - 1);
			var hasTileUp: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.y = tile.y + 1;
			var hasTileDown: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.x = tile.x - 1;
			neighbour.y = tile.y;
			var hasTileLeft: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.x = tile.x + 1;
			var hasTileRight: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));

			var frameIndex: Int = 0;
			frameIndex |= hasTileRight;
			frameIndex |= hasTileLeft << 1;
			frameIndex |= hasTileDown << 2;
			frameIndex |= hasTileUp << 3;

			tileGraphic.animation.frameIndex = frameIndex;
			tileGraphic.alpha = 0.6;
			attackRange.add(tileGraphic);
		}
	}

	public function isTileFree(posX: Int, posY: Int): Bool {
		return
			getCurrentPlayer().getUnitInTile(MapUtils.coordsToIndex(posX, posY)) == null ||
			(posX == selectedUnit.pos.x && posY == selectedUnit.pos.y) /*||
			isCompatibleTransport(selectedUnit, posX, posY) != null*/;
	}

	public function onTurnEnd() {
		// Enable all units in army
		for (unit in getCurrentPlayer().army) {
			unit.enable();
		}

		// Add new funds
		/*getCurrentPlayer().funds = Utils.min(maxFunds,
			getCurrentPlayer().funds + getCurrentPlayer().getProperties() * fundsPerProperty);*/

		currentPlayer++;
		if (currentPlayer == players.length) {
			currentPlayer = 0;
			turn++;
		}

		cursorOnFirstUnit();
		//coDialog.refresh();

		transitionOut(function() {
			transitionIn();
		});
	}

	public function cursorOnFirstUnit() {
		var unit: Unit = getFirstUnitInArmy();
		if (unit != null) {
			cursor.pos.x = unit.pos.x;
			cursor.pos.y = unit.pos.y;
			centerCameraOnCursor();
		}
	}

	public function getFirstUnitInArmy(): Unit {
		var unit: Unit = null;
		armyIterator = getCurrentPlayer().army.iterator();

		if (armyIterator.hasNext())
			unit = armyIterator.next();

		return unit;
	}

	public function getNextUnitInArmy(): Unit {
		var unit: Unit = null;

		if (armyIterator.hasNext())
			unit = armyIterator.next();
		else
			unit = getFirstUnitInArmy();

		return unit;
	}

	public function getAttackRange(unit: Unit, reachableTiles: Set<TilePoint> = null): Set<TilePoint> {
		if (tilesInAttackRange == null) {
			tilesInAttackRange = new Set<TilePoint>(TilePoint.equals);
		}

		if (reachableTiles == null) {
			reachableTiles = new Set<TilePoint>(TilePoint.equals);
			reachableTiles.add(unit.pos);
		}

		tilesInAttackRange.clear();

		for (tile in reachableTiles.getAll()) {
			for (i in -1 * unit.atkRangeMax ... unit.atkRangeMax + 1) {
				for (j in -1 * unit.atkRangeMax ... unit.atkRangeMax + 1) {
					var tileIndex = MapUtils.pointToIndex(tile);

					if (!MapUtils.isTileOccupied(this, tileIndex) || TilePoint.equals(tile, unit.pos)) {
						var distance = Utils.abs(i) + Utils.abs(j);
						var newTile: TilePoint = new TilePoint(tile.x + i, tile.y + j);

						if (distance <= unit.atkRangeMax && distance >= unit.atkRangeMin &&
							newTile.x >= 0 && newTile.x < level.width && newTile.y >= 0 &&
							newTile.y < level.height) {

							tilesInAttackRange.add(newTile);
						}
					}
				}
			}
		}

		return tilesInAttackRange;
	}

	override public function getUnitsInAttackRange(unit: Unit): Array<Unit> {
		var tilesInRange = getAttackRange(unit);
		var enemiesInRange = new Array<Unit>();

		for (tile in tilesInRange.getAll()) {
			var index = MapUtils.coordsToIndex(Std.int(tile.x), Std.int(tile.y));
			var enemyUnit = findEnemyUnit(index);
			if (enemyUnit != null)
				enemiesInRange.push(enemyUnit);
		}

		return enemiesInRange;
	}

	public function updateAttackRange() {
		unitsInAttackRange = getUnitsInAttackRange(selectedUnit);

		if (unitsInAttackRange.length == 0) {
			Utils.clearSpriteGroup(attackRange);
		}
	}

	public function findEnemyUnit(index: Int): Unit {
		var unit: Unit = null;
		var found: Bool = false;
		var i = 0;

		while (!found && i < players.length) {
			if (i != currentPlayer) {
				var tempUnit: Unit = players[i].getUnitInTile(index);
				found = tempUnit != null;
				if (found) unit = tempUnit;
			}
			i++;
		}

		return unit;
	}

	public function loadPlayers() {
		for (i in 0 ... level.players) {
			var player: Player = new Player(i);
			//player.funds = player.getProperties() * fundsPerProperty;
			players.push(player);
		}
	}

	public function getCurrentPlayer(): Player {
		return players[currentPlayer];
	}

	public function getAdjacentUnits(unit: Unit, ownArmy: Bool = false): Array<Unit> {
		var units: Array<Unit> = new Array<Unit>();

		if (unit != null) {
			for (i in [-1, 0, 1]) {
				for (j in [-1, 0, 1]) {
					if (Utils.abs(i + j) == 1) {
						var posX: Int = unit.pos.x + i;
						var posY: Int = unit.pos.y + j;
						var index: Int = MapUtils.coordsToIndex(posX, posY);

						if (MapUtils.isInbounds(posX, posY) && MapUtils.isTileOccupied(unit.battle, index) &&
							(!ownArmy || MapUtils.getUnitInTile(unit.battle, index).player == getCurrentPlayer().id)
						) {
							units.push(MapUtils.getUnitInTile(unit.battle, index));
						}
					}
				}
			}
		}

		return units;
	}

	/*public function isCompatibleTransport(unit: Unit, posX: Int, posY: Int): Transport {
		var transport: Transport = null;
		var tileIndex: Int = MapUtils.coordsToIndex(posX, posY);
		var unitsInTile: Array<Unit> = MapUtils.getUnitsInTile(this, tileIndex, true);

		var found: Bool = false;
		var index: Int = 0;

		while (!found && index < unitsInTile.length) {
			if (unitsInTile[index].isTransport()) {
				transport = cast(unitsInTile[index], Transport);
				found = transport.canLoad(unit);
				if (!found) transport = null;
			}
			index++;
		}

		return transport;
	}*/

	public function syncIdleAnimations() {
		for (player in players) {
			for (unit in player.army) {
				if (unit.sprite.animation.curAnim != null
				 && unit.sprite.animation.curAnim.name == "idle") {
					unit.sprite.animation.curAnim.restart();
				}
			}
		}

		cursor.animation.curAnim.restart();
	}
}
