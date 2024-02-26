extends Node2D

var power = 0
var max_power = 100
var power_increase_rate = 10
var delta = 0
var arrow_scene = preload("res://arrow.tscn")
var sfx_shootBow = preload("res://audio/shootBow.wav")
var sfx_loadBow = preload("res://audio/bowLoad.mp3")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func pull_back():
	$Sprite2D.frame = 1
	sfxManager(sfx_loadBow)

func release():
	$Sprite2D.frame = 0
	sfxManager(sfx_shootBow)

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()
