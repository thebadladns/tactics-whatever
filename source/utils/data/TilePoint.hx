package utils.data;

import flixel.math.FlxPoint;
import utils.Utils;

class TilePoint {

	public var x: Int;
	public var y: Int;

	public function new(x: Int, y: Int) {
		this.x = x;
		this.y = y;
	}

	public static function equals(a: TilePoint, b: TilePoint): Bool {
		return a.x == b.x && a.y == b.y;
	}

	public static function toFlxPoint(tilePoint: TilePoint): FlxPoint {
		return new FlxPoint(tilePoint.x, tilePoint.y);
	}

	public static function fromFlxPoint(point: FlxPoint): TilePoint {
		return new TilePoint(Std.int(point.x), Std.int(point.y));
	}

	public static function distance(a: TilePoint, b: TilePoint): Int {
		return Utils.abs(b.x - a.x) + Utils.abs(b.y - a.y);
	}

	public function toString(): String {
		return "(" + Std.string(x) + ", " + Std.string(y) + ")";
	}
}
