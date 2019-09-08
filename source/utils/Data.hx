package utils;

import sys.io.File;
import haxe.Json;

import utils.data.UnitType;
//import utils.data.BuildingType;
import utils.data.TerrainType;

class Data {

	private static var instance: Data = null;

	public var unitList: Dynamic;
	//public var buildingList: Dynamic;
	public var terrainList: Dynamic;

	//public var landUnits: Array<UnitType>;
	//public var buildings: Map<String, BuildingType>;
	public var units: Map<String, UnitType>;
	public var terrains: Map<String, TerrainType>;

	private function new() {
		unitList = loadJSONFromFile("assets/data/units.json");
		//buildingList = loadJSONFromFile("assets/data/buildings.json");
		terrainList = loadJSONFromFile("assets/data/terrain.json");

		//landUnits = new Array<UnitType>();
		//buildings = new Map<String, BuildingType>();
		units = new Map<String, UnitType>();
		terrains = new Map<String, TerrainType>();

		for (unitName in Reflect.fields(unitList)) {
			var unitData = Reflect.field(unitList, unitName);
			var env = Reflect.field(unitData, "env");
			var unit = new UnitType(unitData);

			units.set(Reflect.field(unitData, "uName"), unit);

			/*switch env {
				case "land":
					landUnits.push(unit);
			}*/
		}

		/*for (buildingName in Reflect.fields(buildingList)) {
			var buildingData = Reflect.field(buildingList, buildingName);
			buildings.set(Reflect.field(buildingData, "uName"), new BuildingType(buildingData));
		}*/

		for (terrainName in Reflect.fields(terrainList)) {
			var terrainData = Reflect.field(terrainList, terrainName);
			terrains.set(Reflect.field(terrainData, "uName"), new TerrainType(terrainData));
		}
	}

	public static function getInstance(): Data {
		if (instance == null)
			instance = new Data();

		return instance;
	}

	public static function loadJSONFromFile(path: String): Dynamic {
		return Json.parse(File.getContent(path));
	}
}
