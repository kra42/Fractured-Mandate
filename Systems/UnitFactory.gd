class_name UnitFactory
extends RefCounted

# Preloading scripts ensures Godot updates these paths if you move files in the editor!
const SCRIPT_ZHAO_YUN = preload("res://Entities/Heroes/Zhao_Yun.gd")
const SCRIPT_LIU_BEI = preload("res://Entities/Heroes/Liu_Bei.gd")
const SCRIPT_SOLDIER = preload("res://Entities/Heroes/SoldierDummy.gd")
const SCRIPT_ARCHER = preload("res://Entities/Heroes/ArcherDummy.gd")

# Preloading textures is also safer
const TEX_ZHAO_YUN = preload("res://Assets/Heroes/Zhao_Yun.png")
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
		"texture": TEX_ZHAO_YUN, # Placeholder
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
	
	# ... rest of the logic remains the same ...
	
	# Texture
	var sprite_node = unit_instance.get_node("Sprite2D")
	if data.has("texture") and data["texture"] != null:
		sprite_node.texture = data["texture"]
		
	# ...
	return unit_instance
