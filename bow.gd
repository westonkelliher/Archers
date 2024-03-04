extends Node2D


@export var draw_time: float = .5
@export var charge_time: float = 4
@export var max_power: float = 50.0


var is_pulling = false
var time_pulling: float = 0
var charge_amount: float = 0 # 0 - 1

var power = 0
var delta = 0
var arrow_scene = preload("res://arrow.tscn")
var sfx_shootBow = preload("res://audio/shootBow.wav")
var sfx_loadBow = preload("res://audio/bowLoad.mp3")


################################################################################
func _ready():
	$Arrow.visible = false
	pass

func _process(delta):
	if !is_pulling:
		return
	time_pulling += delta
	if time_pulling > draw_time:
		$Sprite2D.frame = 2
		$Arrow.visible = true
		charge_amount = min(1, (time_pulling - draw_time)/charge_time)


################################################################################
func pull_back(dead):
	is_pulling = true
	$Sprite2D.frame = 1
	if !dead:
		sfxManager(sfx_loadBow)

func release(dead):
	is_pulling = false
	$Arrow.visible = false
	time_pulling = 0
	charge_amount = 0
	$Sprite2D.frame = 0
	if !dead:
		sfxManager(sfx_shootBow)

func get_power():
	return charge_amount*max_power

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()
