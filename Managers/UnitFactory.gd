class_name UnitFactory
extends RefCounted

const HERO_DB = {
	"ZHAO_YUN": {
		"script": "res://Heroes/Zhao_Yun.gd", 
		"base_stats": {},
		"texture": "res://Images_Heroes/Zhao_Yun.png",
		"display_name": "Zhao Yun"
	},
	"SOLDIER_DUMMY": {
		"script": "res://Heroes/SoldierDummy.gd",
		"base_stats": {},
		"texture": "res://Images_Heroes/Soldier_Dummy.png",
		"display_name": "Soldier"
	},
	"ARCHER_DUMMY": {
		"script": "res://Heroes/ArcherDummy.gd", 
		"base_stats": {"hp": 8, "atk": 4, "class": "ARCHER"},
		"texture": "res://Images_Heroes/Archer_Dummy.png",
		"display_name": "Archer"
	}
}

static func create_unit(hero_id: String, player_id: String, grid_pos: Vector2i, unit_scene: PackedScene) -> Unit:
	if not HERO_DB.has(hero_id):
		push_error("Hero ID not found: " + hero_id)
		return null

	var data = HERO_DB[hero_id]
	var unit_instance = unit_scene.instantiate()
	
	# Attach Script
	if data.has("script") and data["script"] != "":
		var hero_script = load(data["script"])
		if hero_script: 
			unit_instance.set_script(hero_script)
	
	# Identity
	unit_instance.grid_pos = grid_pos
	unit_instance.player_id = player_id
	unit_instance.z_index = grid_pos.y 
	unit_instance.set_meta("hero_id", hero_id)
	
	var disp_name = data.get("display_name", hero_id)
	unit_instance.name = disp_name # Set Node Name for logs
	
	# Texture
	var sprite_node = unit_instance.get_node("Sprite2D")
	if data.has("texture") and data["texture"] != "":
		var tex = load(data["texture"])
		if tex: 
			sprite_node.texture = tex
	
	# Stats
	if data.has("base_stats") and not data["base_stats"].is_empty():
		var stats = data["base_stats"]
		if stats.has("hp"): unit_instance.max_hp = stats["hp"]
		if stats.has("hp"): unit_instance.current_hp = stats["hp"]
		if stats.has("atk"): unit_instance.attack_power = stats["atk"]
		if stats.has("class"): unit_instance.unit_class = stats["class"]
		
	return unit_instance
