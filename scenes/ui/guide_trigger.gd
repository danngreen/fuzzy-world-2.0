extends Node2D

@export var guide_id: String = ""
@export var trigger_radius: float = 120.0
@export var dismiss_radius: float = 250.0


func _ready():
	add_to_group("guide_triggers")
