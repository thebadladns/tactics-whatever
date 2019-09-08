import flixel.FlxG;

import entities.Unit;

import states.BattleState;

import utils.MapUtils;

class Player {
	//public var army: Map<Int, Unit>;
	public var army: Array<Unit>;
	public var id: Int;
	public var funds: Int;

	private var _map: BattleState;

	public function new(id: Int) {
		this.id = id;

		funds = 0;
		army = new Array<Unit>();

		if (_map == null)
			_map = cast(FlxG.state, BattleState);
	}

	public function getTotalActiveUnits(): Int {
		var activeUnits: Int = 0;

		for (unit in army) {
			if (unit.status == UnitStatus.STATUS_AVAILABLE) {
				activeUnits++;
			}
		}

		return activeUnits;
	}

	/*public function getProperties(): Int {
		var properties: Int = 0;

		for (key in _map.buildings.keys()) {
			if (_map.buildings.get(key).belongsTo == id) {
				properties++;
			}
		}

		return properties;
	}*/

	public function getUnitInTile(tileIndex: Int): Unit {
		var units: Array<Unit> = getUnitsInTile(tileIndex);

		return units.length > 0 ? units[0] : null;
	}

	public function getUnitsInTile(tileIndex: Int): Array<Unit> {
		var units: Array<Unit> = new Array<Unit>();

		for (unit in army) {
			if (MapUtils.coordsToIndex(unit.pos.x, unit.pos.y) == tileIndex)
				units.push(unit);
		}

		return units;
	}
}
