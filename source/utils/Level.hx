package utils;

import haxe.ds.ArraySort;

import utils.tiled.TiledMap;
import utils.tiled.TiledTileSet;
import utils.tiled.TiledLayer;
import utils.tiled.TiledObject;
import utils.tiled.TiledObjectGroup;

import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.FlxObject;

import entities.Unit;
/*import entities.Building;
import entities.BuildingBase;
import entities.BuildingHQ;
import entities.BuildingCity;*/

import utils.MapUtils;
import utils.Data;
import utils.Utils;

class Level extends TiledMap {

	public var backgroundTiles: FlxTypedGroup<FlxObject>;
	public var tileMap: FlxTilemap;

	//public var buildings: Array<Building>;
	public var units: Array<Unit>;
	public var players: Int;

	public function new(level: Dynamic) {
		super(level);

		backgroundTiles = new FlxTypedGroup<FlxObject>();

		for (layer in layers) {
			var tileset = obtainTileSet(this, layer);

			if (tileset == null)
				throw "Tileset could not be found. Check the name in the layer 'tileset' property or something.";

			var tileMapPath: String = "assets/images/basictiles.png";
			var tilemap: FlxTilemap = new FlxTilemap();
			tilemap.loadMapFromArray(layer.tileArray, width, height, tileMapPath, tileset.tileWidth, tileset.tileHeight, 1, 1, 1);

			backgroundTiles.add(tilemap);
		}

		MapUtils.mapWidth = width;
		MapUtils.mapHeight = height;

		players = 0;

		//buildings = new Array<Building>();
		units = new Array<Unit>();

		parseEntities();
	}

	private function parseEntities() {
		for (objectGroup in objectGroups) {
			switch objectGroup.name {
				/*case "Buildings":
					parseBuildings(objectGroup);*/
				case "Units":
					parseUnits(objectGroup);
			}

		}
	}

	/*private function parseBuildings(buildingGroup: TiledObjectGroup) {
		for (buildingObj in buildingGroup.objects) {
			var building: Building = null;
			var posX: Int = Std.int(buildingObj.x / ViewPort.tileSize);
			var posY: Int = Std.int(buildingObj.y / ViewPort.tileSize);

			switch buildingObj.custom.get("buildingType") {
				case "hq": building = new BuildingHQ(0, 0);
				case "base": building = new BuildingBase(0, 0);
				case "airport":
				case "port":
				case "city": building = new BuildingCity(0, 0);
			}

			if (building != null) {
				var player: Int = Std.parseInt(buildingObj.custom.get("player"));
				players = Utils.max(players, player + 1);

				building.setBelongsTo(player);
				building.place(posX, posY);
				buildings.push(building);
			}

		}

		// sort buildings so that buildings in the last rows appear on top (correct z-index)
		ArraySort.sort(buildings, function(ba: Building, bb: Building): Int {
			return MapUtils.coordsToIndex(ba.posX, ba.posY) - MapUtils.coordsToIndex(bb.posX, bb.posY);
		});
	}*/

	private function parseUnits(unitGroup: TiledObjectGroup) {
		for (unitObj in unitGroup.objects) {
			var posX: Int = Std.int(unitObj.x / ViewPort.tileSize);
			var posY: Int = Std.int(unitObj.y / ViewPort.tileSize);
			var unitType: String = unitObj.custom.get("unitType");
			var unit: Unit = null;

			if (unitType != null && Data.getInstance().units.exists(unitType)) {
				var player: Int = Std.parseInt(unitObj.custom.get("player"));
				players = Utils.max(players, player + 1);

				unit = UnitFactory.create(posX, posY, Data.getInstance().units.get(unitType), player);
				unit.player = player;
				units.push(unit);
			}
		}
	}

	public static function obtainTileSet(map: TiledMap, layer: TiledLayer): TiledTileSet {
		var tilesetName: String = layer.properties.get("tileset");
		if (tilesetName == null || !map.tilesets.exists(tilesetName))
			throw "'tileset' property not defined for the " + layer.name + " layer. Please, add the property to the layer.";

		return map.tilesets.get(tilesetName);
	}

}
