extends Node
var mainScene = null

func damageNumbers(damageNum : int, position : Vector2):
	var number = Label.new()
	number.global_position = position
	number.text = str(damageNum)
	
	number.label_settings = LabelSettings.new()
