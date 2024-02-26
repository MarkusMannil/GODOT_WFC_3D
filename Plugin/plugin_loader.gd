tool
extends EditorPlugin

const rule_add_addon = preload("res://Plugin/plugin_add_rule.tscn")

var docked_scene

func _enter_tree():
	docked_scene = rule_add_addon.instance()
	add_control_to_bottom_panel(docked_scene, "Object rules")
	pass
	
func _exit_tree():
	remove_control_from_docks(docked_scene)
	docked_scene.free
	pass

