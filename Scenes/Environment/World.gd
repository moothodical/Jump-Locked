extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	SoundManager.play_bgm("forest")
	SoundManager.set_volume_db(-20, "forest")
