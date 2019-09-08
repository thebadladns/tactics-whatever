package utils.data;

class TerrainType {
	public var name: String;
	public var uName: String;
	public var def: Int;
	public var frameIndex: Int;
	public var movCost: Map<String, Int>;

	public function new(data: Dynamic) {
		uName = Reflect.field(data, "uName");
		name = Reflect.field(data, "name");
		def = Reflect.field(data, "def");
		frameIndex = Reflect.field(data, "frameIndex");

		movCost = new Map<String, Int>();
		var movCosts = Reflect.field(data, "movCost");
		for (movType in Reflect.fields(movCosts)) {
			movCost.set(movType, Reflect.field(movCosts, movType));
		}
	}
}
