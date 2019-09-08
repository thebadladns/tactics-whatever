package utils;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;

import entities.Entity;

class Scene {
	public static var currentObjId: Int = 0;

	private var layers: Map<String, SceneLayer>;
	private var layerArray: Array<SceneLayer>;
	private var members: Array<FlxObject>;

	public function new() {
		layers = new Map<String, SceneLayer>();
		layerArray = new Array<SceneLayer>();
		members = new Array<FlxObject>();
	}

	public function addLayer(name: String) {
		var layer: SceneLayer = new SceneLayer(name, layerArray.length + 1);
		layers.set(name, layer);
		layerArray.push(layer);
	}

	public function getLayer(name: String): SceneLayer {
		return layers.get(name);
	}

	public function sortMembers(): Array<FlxObject> {
		members.splice(0, members.length);
		for (i in 0 ... layerArray.length) {
			var layer: SceneLayer = layerArray[i];
			if (layer.sortable) layer.sort();

			for (j in 0 ... layer.members.length) {
				members.push(layer.members[j]);
			}
		}

		return members;
	}

	public function update(state: FlxState) {
		state.members.splice(0, state.members.length);
		sortMembers();

		for (i in 0 ... members.length) {
			state.add(members[i]);
		}
	}

	public function moveLayerUp(layerName: String) {
		var layer: SceneLayer = layers.get(layerName);
		if (layer != null) {
			if (layer.zIndex + 1 < layerArray.length) {
				swapLayers(layer.zIndex, layer.zIndex + 1);
			}
		}
	}

	public function moveLayerDown(layerName: String) {
		var layer: SceneLayer = layers.get(layerName);
		if (layer != null) {
			if (layer.zIndex - 1 >= 0) {
				swapLayers(layer.zIndex, layer.zIndex - 1);
			}
		}
	}

	private function swapLayers(index1: Int, index2: Int) {
		if (index1 >= 0 && index1 < layerArray.length && index2 >= 0 && index2 < layerArray.length) {
			var aux: SceneLayer = layerArray[index2];
			layerArray[index2] = layerArray[index1];
			layerArray[index1] = aux;

			layerArray[index1].zIndex = index1;
			layerArray[index2].zIndex = index2;
		}
	}

	public function moveEntity(entityId: Int, from: String, to: String) {
		var fromLayer: SceneLayer = layers.get(from);
		var toLayer: SceneLayer = layers.get(to);

		if (fromLayer != null && toLayer != null && fromLayer.findById(entityId) != null) {
			var entity: Dynamic = fromLayer.removeById(entityId);
			toLayer.add(entity);
		}
	}
}

class SceneLayer {
	public var zIndex: Int;
	public var name: String;
	public var sortable: Bool;

	public var members: Array<Dynamic>;

	public function new(name: String, zIndex: Int, sortable: Bool = false) {
		this.name = name;
		this.zIndex = zIndex;

		members = new Array<Dynamic>();
	}

	public function add(entity: Dynamic) {
		var id: Int = cast(Reflect.field(entity, "ID"), Int);
		if (id < 0) {
			Reflect.setField(entity, "ID", Scene.currentObjId++);
		}

		members.push(entity);
	}

	public function sort() {
		members.sort(function(a: Dynamic, b: Dynamic) {
			var ax: Int = cast(Reflect.field(a, "x"), Int);
			var ay: Int = cast(Reflect.field(a, "y"), Int);
			var bx: Int = cast(Reflect.field(b, "x"), Int);
			var by: Int = cast(Reflect.field(b, "y"), Int);

			return MapUtils.coordsToIndex(ax, ay) - MapUtils.coordsToIndex(bx, by);
		});
	}

	public function findById(id: Int): Dynamic {
		var member: Dynamic = null;
		var found: Bool = false;
		var index: Int = 0;

		while (!found && index < members.length) {
			var memberId = cast(Reflect.field(members[index], "ID"), Int);
			found = memberId == id;
			index++;
		}

		if (found) member = members[index - 1];

		return member;
	}

	public function removeById(id: Int): Dynamic {
		var member: Dynamic = null;
		var found: Bool = false;
		var index: Int = 0;

		while (!found && index < members.length) {
			var memberId = cast(Reflect.field(members[index], "ID"), Int);
			found = memberId == id;
			index++;
		}

		if (found) {
			member = members[index - 1];
			members.splice(index - 1, 1);
		}

		return member;
	}
}
