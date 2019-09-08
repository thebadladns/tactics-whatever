package utils.data;

class UnitType {
	public static var unitFrames: Int = 16;

	public var id: Int;
	public var name: String;
	public var uName: String;
	public var shortName: String;
	public var gfxPath: String;
	public var type: String;
	public var movType: String;
	public var mov: Int;
	public var res: Int;
	//public var fuel: Int;
	public var vision: Int;
	//public var weapons: Array<WeaponType>;

	public var animIdle: Array<Int>;
	public var animWalkDown: Array<Int>;
	public var animWalkLR: Array<Int>;
	public var animWalkUp: Array<Int>;

	public function new(data: Dynamic) {
		id = Reflect.field(data, "id");
		name = Reflect.field(data, "name");
		uName = Reflect.field(data, "uName");
		shortName = Reflect.field(data, "shortName");
		gfxPath = Reflect.field(data, "gfx-path");
		type = Reflect.field(data, "type");
		movType = Reflect.field(data, "movType");
		mov = Reflect.field(data, "mov");
		res = Reflect.field(data, "res");
		//fuel = Reflect.field(data, "fuel");
		vision = Reflect.field(data, "vision");

		animIdle = Reflect.field(data, "anim-idle");
		animWalkDown = Reflect.field(data, "anim-walk-down");
		animWalkLR = Reflect.field(data, "anim-walk-lr");
		animWalkUp = Reflect.field(data, "anim-walk-up");

		/*weapons = new Array<WeaponType>();
		var weaponsData: Array<Dynamic> = Reflect.field(data, "weapons");
		for (weaponData in weaponsData) {
			var weapon = new WeaponType(weaponData);
			weapons.push(weapon);
		}*/
	}
}
