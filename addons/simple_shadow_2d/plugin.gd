@tool
extends EditorPlugin


func _enter_tree() -> void:
	var icon := load("res://icon.svg") as Texture2D
	add_custom_type("Shadow2D", "Node2D", preload("shadow_2d.gd"), icon)



func _exit_tree() -> void:
	remove_custom_type("Shadow2D")
