extends Area2D

#var functionTest : Callable
signal buttonFunction
var buttonText : String
var state = null

func _ready():
	$CenterContainer2/ButtonText.text = buttonText
	pass

func _on_body_entered(body):
	if !(body is Arrow):
		return
	body.hitButton()
	Autoloader.buttonRef = self
	emit_signal("buttonFunction")
	pass # Replace with function body.

func setText(text : String):
	$CenterContainer2/ButtonText.text = text
	
func getText():
	return $CenterContainer2/ButtonText.text
