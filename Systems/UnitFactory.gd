class_name UnitFactory
extends RefCounted

# UPDATED PATHS: Manually fixed to match your new folder structure.

# Scripts are now in subfolders:
const SCRIPT_ZHAO_YUN = preload("res://Entities/Heroes/Shu/Zhao_Yun.gd")
const SCRIPT_LIU_BEI = preload("res://Entities/Heroes/Shu/Liu_Bei.gd")
const SCRIPT_SOLDIER = preload("res://Entities/Heroes/AI/SoldierDummy.gd")
const SCRIPT_ARCHER = preload("res://Entities/Heroes/AI/ArcherDummy.gd")

# Textures are directly in Assets/Heroes:
const TEX_ZHAO_YUN = preload("res://Assets/Heroes/Zhao_Yun.png")
const TEX_LIU_BEI = preload("res://Assets/Heroes/Liu_Bei_2.png")
const TEX_SOLDIER = preload("res://Assets/Heroes/Soldier_Dummy.png")
const TEX_ARCHER = preload("res://Assets/Heroes/Archer_Dummy.png")

const HERO_DB = {
	"ZHAO_YUN": {
		"script": SCRIPT_ZHAO_YUN, 
		"base_stats": {},
		"texture": TEX_ZHAO_YUN,
		"display_name": "Zhao Yun"
	},
	"LIU_BEI": {
		"script": SCRIPT_LIU_BEI, 
		"base_stats": {},
		"texture": TEX_LIU_BEI, 
		"display_name": "Liu Bei"
	},
	"SOLDIER_DUMMY": {
		"script": SCRIPT_SOLDIER,
		"base_stats": {},
		"texture": TEX_SOLDIER,
		"display_name": "Soldier"
	},
	"ARCHER_DUMMY": {
		"script": SCRIPT_ARCHER, 
		"base_stats": {"hp": 8, "atk": 4, "class": "ARCHER"},
		"texture": TEX_ARCHER,
		"display_name": "Archer"
	}
}

static func create_unit(hero_id: String, player_id: String, grid_pos: Vector2i, unit_scene: PackedScene) -> Unit:
	if not HERO_DB.has(hero_id):
		push_error("Hero ID not found: " + hero_id)
		return null

	var data = HERO_DB[hero_id]
	var unit_instance = unit_scene.instantiate()
	
	# Attach Script (Now using the preloaded constant directly)
	if data.has("script") and data["script"] != null:
		unit_instance.set_script(data["script"])
	
	# Identity
	unit_instance.grid_pos = grid_pos
	unit_instance.player_id = player_id
	unit_instance.z_index = grid_pos.y 
	unit_instance.set_meta("hero_id", hero_id)
	
	var disp_name = data.get("display_name", hero_id)
	unit_instance.name = disp_name # Set Node Name for logs
	
	# Texture
	var sprite_node = unit_instance.get_node("Sprite2D")
	if data.has("texture") and data["texture"] != null:
		sprite_node.texture = data["texture"]
		
	# Stats
	if data.has("base_stats") and not data["base_stats"].is_empty():
		var stats = data["base_stats"]
		if stats.has("hp"): unit_instance.max_hp = stats["hp"]
		if stats.has("hp"): unit_instance.current_hp = stats["hp"]
		if stats.has("atk"): unit_instance.attack_power = stats["atk"]
		if stats.has("class"): unit_instance.unit_class = stats["class"]
		
	return unit_instance
