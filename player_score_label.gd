extends MarginContainer
class_name PlayerScoreLabel
var playerName : String
var playerScore : int = 0
var playerColor : Color
var won : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer2/PlayerName.add_theme_color_override("font_color", playerColor)
	$HBoxContainer2/PlayerName.text = playerName
	if won:
		$HBoxContainer2/PlayerName.text += " ★"
	$HBoxContainer2/Score.text = str(playerScore)
