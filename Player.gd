extends KinematicBody2D

const GRAVITY = Vector2(0, -1)
const G_FORCE = 10
const MAX_SPEED = 65
const ACCELERATE = 40
const JUMP_FORCE = -190
const BOUNCING = 150

const BOMB_LOAD = preload("res://bullets/Bomb.tscn")

onready var bomb_counter = get_node("/root/main/")
onready var check_anim = get_node("PlayerSprite")
onready var throw_timer = $ThrowTimer
onready var oxygen_timer = $OxygenTimer

var motion = Vector2()
var check_input#key_mapping
var environment
var falling = false
var player_immune = false
var pushing

func _ready():
	oxygen_timer.connect("timeout", self, "player_breathing")
	oxygen_timer.start()

func player_push():
	if $PushRay.is_colliding():
		return "push"
	elif !$PushRay.is_colliding():
		return "not_push"
#OXYGEN
func player_breathing():
	if $DiveRay.is_colliding() and get_node("/root/main").player_oxy > 0:
		get_node("/root/main").player_oxy -= 0.5
	elif $DiveRay.is_colliding() and get_node("/root/main").player_oxy == 0 and get_node("/root/main").player_hp == 3:
		get_node("/root/main").player_hp -= 1
		get_node("/root/main").player_oxy = 50
	elif $DiveRay.is_colliding() and get_node("/root/main").player_oxy == 0 and get_node("/root/main").player_hp == 2:
		get_node("/root/main").player_hp -= 1
		get_node("/root/main").player_oxy = 25
	elif $DiveRay.is_colliding() and get_node("/root/main").player_oxy == 0 and get_node("/root/main").player_hp == 1:
		get_node("/root/main").player_hp -= 1
		get_node("/root/main").player_oxy = 10
	elif !$DiveRay.is_colliding() and get_node("/root/main").player_oxy < 100 and get_node("/root/main").player_hp > 0:
		get_node("/root/main").player_oxy += 2
	else:
		get_node("/root/main").player_oxy = 100

func player_behaviour():
	if !is_on_floor() and !$PushRay.is_colliding() and !$SwimRay.is_colliding() and !$DiveRay.is_colliding() and !$ClimbRay.is_colliding():
		return "air"
	elif is_on_floor() and !$PushRay.is_colliding() and !$SwimRay.is_colliding() and !$DiveRay.is_colliding() and !$ClimbRay.is_colliding():
		return "ground"
	elif !is_on_floor() and $DiveRay.is_colliding() and !$ClimbRay.is_colliding():
		return "under_water"
	elif is_on_floor() and $DiveRay.is_colliding() and !$ClimbRay.is_colliding():
		return "under_water"
	elif !is_on_floor() and $SwimRay.is_colliding() and !$ClimbRay.is_colliding():
		return "on_water"
	elif is_on_floor() and $SwimRay.is_colliding() and !$ClimbRay.is_colliding():
		return "on_water"
	elif is_on_floor() and $ClimbRay.is_colliding():
		return "alpinist"
	elif !is_on_floor() and $ClimbRay.is_colliding():
		return "alpinist"
	
	#elif is_on_wall() and !is_on_floor() and !$ClimbRay.is_colliding():
	#	return "pushing"
	
	else:
		return "none"

func input_mapping():#check_input
	if Input.is_action_just_pressed("ui_select"):
		return "J_JP"
	elif Input.is_action_just_pressed("ui_accept"):
		return "B_JP"
	elif Input.is_action_pressed("ui_up"):
		return "up"
	elif Input.is_action_pressed("ui_left"):
		return "left"
	elif Input.is_action_pressed("ui_right"):
		return "right"
	elif Input.is_action_pressed("ui_down"):
		return "down"
	else:
		return "none"
#HIT BOUNCE and IMMUNITY
func Player_Bounce():
	motion.y = -(BOUNCING)
	if $PlayerSprite.flip_h == true:
		motion.x = BOUNCING
	else:
		motion.x = -BOUNCING

func Player_UP_Bounce():
	motion.y = BOUNCING

func Player_Immunity():
		$FlashPlayer.play("immune_anim")
		player_immune = true

func _on_FlashPlayer_animation_finished(anim_name):
	if anim_name == "immune_anim":
		$FlashPlayer.play("empty")
		player_immune = false
#PROCESS
func _physics_process(_delta):
	pushing = player_push()
	environment = player_behaviour()
	check_input = input_mapping()#key_mapping = check_input

	motion.y = clamp(motion.y, -200, 400)
	
	if $DamageCheck.check_damage == "hit":
		check_anim.anim_state = "damaged"
#DEAD BY FALL
	if motion.y > 0:
		print(motion.y)
	if motion.y == 400:
		falling = true
	if falling == true:
		get_node("/root/main").player_hp = 0

#GRAVITY
	if environment == "air" or environment == "ground":
		motion.y += G_FORCE
	elif environment == "under_water":
		motion.y = lerp(motion.y, -6, 0.50)
	else:
		if environment == "alpinist":
			motion.y = 0
#JUMPING
	if check_input == "J_JP" and environment == "ground":
		motion.y = JUMP_FORCE
	elif check_input == "J_JP" and pushing == "push":
		motion.y = JUMP_FORCE
	elif check_input == "J_JP" and environment == "on_water":
			motion.y = lerp(motion.y, -18, 8)	
	else:
		if motion.y < 0 and !environment == "on_water" and !check_anim.anim_state == "throw" and $DamageCheck.check_damage == "nohit":
			check_anim.anim_state = "jump"
		else:
			if motion.y > 0 and !environment == "on_water" and $DamageCheck.check_damage == "nohit":
				check_anim.anim_state = "fall"
#CLIMBING
	if check_input == "up" and environment == "alpinist":
		check_anim.anim_state = "climb"
		motion.y = max(motion.y-ACCELERATE, -MAX_SPEED)
	else:
		if check_input == "down" and environment == "alpinist":
			check_anim.anim_state = "climb"
			motion.y = max(motion.y+ACCELERATE, -MAX_SPEED)
#AIR
	if check_input == "left" and environment == "air":
		motion.x = max(motion.x-ACCELERATE, -MAX_SPEED)
		$PlayerSprite.flip_h = true
		if sign($BombPosition.position.x) == 1:
			$BombPosition.position.x *= -1
		$DiveRay.cast_to = Vector2(-16, 0)
	else:
		if check_input == "right" and environment == "air":
			motion.x = min(motion.x+ACCELERATE, MAX_SPEED)
			$PlayerSprite.flip_h = false
			if sign($BombPosition.position.x) == -1:
				$BombPosition.position.x *= -1
			$DiveRay.cast_to = Vector2(16, 0)
#GROUND
	if check_input == "left" and (environment == "ground" or environment == "alpinist") and pushing == "not_push" and $DamageCheck.check_damage == "nohit":
		check_anim.anim_state = "run"
		motion.x = max(motion.x-ACCELERATE, -MAX_SPEED)
		$PlayerSprite.flip_h = true
		if sign($BombPosition.position.x) == 1:
			$BombPosition.position.x *= -1
		$DiveRay.cast_to = Vector2(-16, 0)
		$PushRay.cast_to = Vector2(-7, 0)
	else:
		if check_input == "right" and (environment == "ground" or environment == "alpinist") and pushing == "not_push" and $DamageCheck.check_damage == "nohit":
			check_anim.anim_state = "run"
			motion.x = min(motion.x+ACCELERATE, MAX_SPEED)
			$PlayerSprite.flip_h = false
			if sign($BombPosition.position.x) == -1:
				$BombPosition.position.x *= -1
			$DiveRay.cast_to = Vector2(16, 0)
			$PushRay.cast_to = Vector2(7, 0)
#WATER
	if check_input == "down" and (environment == "under_water" or environment == "on_water") and $DamageCheck.check_damage == "nohit":
		check_anim.anim_state = "swim"
		motion.y = max(motion.y+ACCELERATE /3, -MAX_SPEED)
		$PlayerCollision.rotation = 11
		$DamageCheck/CollisionShape2D.rotation = 11
	elif check_input == "up" and environment == "under_water" and $DamageCheck.check_damage == "nohit":
		check_anim.anim_state = "swim"
		motion.y = min(motion.y-ACCELERATE /3, MAX_SPEED)
		$PlayerCollision.rotation = 11
		$DamageCheck/CollisionShape2D.rotation = 11
	elif check_input == "left" and (environment == "under_water" or environment == "on_water") and $DamageCheck.check_damage == "nohit":
		check_anim.anim_state = "swim"
		motion.x = max(motion.x-ACCELERATE, -MAX_SPEED)/2
		$PlayerSprite.flip_h = true
		if sign($BombPosition.position.x) == 1:
			$BombPosition.position.x *= -1
		$DiveRay.cast_to = Vector2(-16, 0)
		$PlayerCollision.rotation = 11
		$DamageCheck/CollisionShape2D.rotation = 11
	elif check_input == "right" and (environment == "under_water" or environment == "on_water") and $DamageCheck.check_damage == "nohit":
		check_anim.anim_state = "swim"
		motion.x = min(motion.x+ACCELERATE, MAX_SPEED)/2
		$PlayerSprite.flip_h = false
		if sign($BombPosition.position.x) == -1:
			$BombPosition.position.x *= -1
		$DiveRay.cast_to = Vector2(16, 0)
		$PlayerCollision.rotation = 11
		$DamageCheck/CollisionShape2D.rotation = 11
	else:
		$PlayerCollision.rotation = 0
		$DamageCheck/CollisionShape2D.rotation = 0
#PUSHING
	if check_input == "left" and pushing == "push":
		check_anim.anim_state = "push"
		motion.x = max(motion.x-ACCELERATE, -MAX_SPEED)
		$PlayerSprite.flip_h = true
		if sign($BombPosition.position.x) == 1:
			$BombPosition.position.x *= -1
		$DiveRay.cast_to = Vector2(-16, 0)
	else:
		if check_input == "right" and pushing == "push":
			check_anim.anim_state = "push"
			motion.x = min(motion.x+ACCELERATE, MAX_SPEED)
			$PlayerSprite.flip_h = false
			if sign($BombPosition.position.x) == -1:
				$BombPosition.position.x *= -1
			$DiveRay.cast_to = Vector2(16, 0)
#STOP MOVEMENT
	if check_input == "none" and environment == "ground":
		motion.x = lerp(motion.x, 0, 0.25)
		check_anim.anim_state = "idle"
	elif check_input == "none" and pushing == "push":
		motion.x = lerp(motion.x, 0, 0.25)
		check_anim.anim_state = "S_push"
	elif check_input == "none" and environment == "alpinist":
		motion.x = lerp(motion.x, 0, 0.25)
		check_anim.anim_state = "S_climb"
	elif check_input == "none" and environment == "air":
		motion.x = lerp(motion.x, 0, 0.05)
	else:
		if check_input == "none" and (environment == "under_water" or environment == "on_water"):
			motion.x = lerp(motion.x, 0, 0.08)
			check_anim.anim_state = "idle_swim"
	if check_input == "down" and environment == "air":
		motion.x = lerp(motion.x, 0, 0.05)
	else:
		if (check_input == "up" or check_input == "down") and environment == "ground":
			motion.x = lerp(motion.x, 0, 0.20)
			check_anim.anim_state = "idle"
	if check_input == "up" and environment == "under_water":
		motion.x = lerp(motion.x, 0, 0.08)
		check_anim.anim_state = "swim"
	elif check_input == "up" and environment == "on_water":
		motion.x = lerp(motion.x, 0, 0.08)
		check_anim.anim_state = "idle_swim"
	else:
		if check_input == "down" and environment == "under_water":
			motion.x = lerp(motion.x, 0, 0.08)
			check_anim.anim_state = "swim"
#BOMBS

	if check_input == "B_JP" and throw_timer.is_stopped() and bomb_counter.player_bmb > 0:
		throw_timer.start()
		bomb_counter.player_bmb -= 1
	if !throw_timer.is_stopped():
		check_anim.anim_state = "throw"
	if check_anim.end_animation == true:# and !is_on_wall():
		throwing_bombs()

	motion = move_and_slide(motion, GRAVITY)

func throwing_bombs():
	var bomb = BOMB_LOAD.instance()
	if sign($BombPosition.position.x) == 1:
		bomb.set_bomb_direction(1)
	elif sign($BombPosition.position.x) == -1:
		bomb.set_bomb_direction(-1)
	get_parent().add_child(bomb)
	bomb.position = $BombPosition.global_position
	check_anim.end_animation = false
	check_anim.anim_state = "idle"

