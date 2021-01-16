extends KinematicBody2D

signal trigger_cutscene
signal player_death
signal player_restart
signal player_get_collectable

onready var sprite = $Sprite
onready var anim = $AnimationPlayer

var has_backpack = false
var collectables = 0
var num_of_keys = 0

var anim_tree

const UP = Vector2(0, -1)
const JUMP_VEL = -200
const MAX_SPEED = 150
const MAX_KEYS = 3

var velocity = Vector2()
var move_speed = 500
var gravity = 500
var move_dir = 1
var is_grounded
var is_unlocked
var can_run

# Called when the node enters the scene tree for the first time.
func _ready():
	can_run = false
	is_unlocked = false
	anim_tree = $AnimationTree.get("parameters/playback")
	
	print("Has backpack? " + str(has_backpack))
	if has_backpack:
		anim_tree.start("run_locked_backpack")
	else:
		anim_tree.start("run_locked")

		
	# Connecting signals
	connect("player_death", get_parent(), "_on_Player_death")
	connect("player_get_collectable", get_parent(), "_on_Player_get_Collectable")

func _physics_process(delta):
	print(can_run)
	check_state()
	if can_run:
		handle_move()
	else:
		wait_for_keypress()
	apply_movement()
	apply_gravity(delta)

func wait_for_keypress():
	if Input.is_action_pressed("move_left"):
		move_dir = -1
		can_run = true
	elif Input.is_action_pressed("move_right"):
		move_dir = 1
		can_run = true

func apply_movement():
	$GroundedLabel.text = str(is_grounded())

	if $Rig/ForwardRaycast.is_colliding():
		flip()
	check_facing_direction()
	velocity = move_and_slide(velocity, UP)
	
	# If player touches water
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.name == "Water":
			print("player died! lol")
			die()

func check_state():
	$UnlockedLabel.text = str(is_unlocked)
	if is_unlocked:
		if has_backpack:
			anim_tree.travel("run_unlocked_backpack")
		else:
			anim_tree.travel("run_unlocked")
	else:
		if has_backpack:
			anim_tree.travel("run_locked_backpack")
		else:
			anim_tree.travel("run_locked")

func apply_gravity(delta):
	velocity.y += gravity * delta

func _input(event):
	if event.is_action_pressed("restart"):
		restart_stage()
	if event.is_action_pressed("jump") && is_grounded():
		if is_unlocked:
			if has_backpack:
				anim_tree.travel("jump_unlocked_backpack")
			else:
				anim_tree.travel("jump_unlocked")
			jump()
		else:
			if has_backpack:
				anim_tree.travel("jump_locked_backpack")
			else:
				anim_tree.travel("jump_locked")
			#jump()
	elif event.is_action_released("jump"):
		velocity.y *= 0.4

func handle_move():
	velocity.x = lerp(velocity.x, MAX_SPEED * move_dir, get_h_weight())

# Player has less control in the air
func get_h_weight():
	return 0.2 if is_grounded() else 0.075

func update_move_dir():
	move_dir =  -int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))

func jump():
	SoundManager.play_se("player_jump")
	SoundManager.set_volume_db(-30, "player_jump")
	velocity.y = JUMP_VEL
	
	if has_backpack:
		dec_keys()
		if num_of_keys == 0:
			is_unlocked = false
	else:
		is_unlocked = false # Lock every time the player jumps

func is_grounded():
	return true if $Rig/GroundedRaycast.is_colliding() else false

# Changes move_dir and flips character Rig and CollisionShape
func flip():
	SoundManager.play_se("player_hit_wall")
	SoundManager.set_volume_db(-30, "player_hit_wall")
	move_dir = -move_dir
	
func check_facing_direction():
	if move_dir == 1:
		$Rig.scale.x = 1
	elif move_dir == -1:
		$Rig.scale.x = -1

func die():
	emit_signal("player_death")

func restart_stage():
	emit_signal("player_restart")          

func get_num_of_Collectables():
	return collectables

func play_walk_sound():
	pass
	#SoundManager.play_se("player_walk_2")
	#SoundManager.set_volume_db(-30, "player_walk_2")

func _on_Player_get_backpack():
	anim_tree.stop()
	has_backpack = true
	anim_tree.start("run_locked_backpack")

func inc_keys():
	if has_backpack:
		num_of_keys += 1
		num_of_keys = clamp(num_of_keys, 0, MAX_KEYS)
		$Rig/KeysLabel.text = str(num_of_keys)
		$Rig/Keys.get_node("Key" + str(num_of_keys)).visible = true

func dec_keys():
	if has_backpack:
		$Rig/Keys.get_node("Key" + str(num_of_keys)).visible = false
		num_of_keys -= 1
		$Rig/KeysLabel.text = str(num_of_keys)
		print(num_of_keys)
		num_of_keys = clamp(num_of_keys, 0, MAX_KEYS)

func clear_keys():
	for key in $Rig/Keys.get_children():
		key.visible = false
	pass
