extends MarginContainer

var score_label_scene = preload("res://player_score_label.tscn")
var scoreRows = [] # what's on the board, so the host can tell clients
# Called when the node enters the scene tree for the first time.

func newScoreLabel(name:String, color:Color, score:int, won:bool = false):
	scoreRows.append([name, color, score, won])
	var scoreLabel = score_label_scene.instantiate()
	scoreLabel.playerName = name
	scoreLabel.playerColor = color
	scoreLabel.playerScore = score
	scoreLabel.won = won
	$MarginContainer/VBoxContainer.add_child(scoreLabel)

func clearScores():
	scoreRows = []
	for child in $MarginContainer/VBoxContainer.get_children():
		if child is PlayerScoreLabel:
			child.queue_free()


#func _ready():
	#if Autoloader.mainScene != null:
		#return
	#newScoreLabel("Missandei", Color.RED, 5)
	#newScoreLabel("Daenerys", Color.BLUE, 5)
	#newScoreLabel("Samwell", Color.DARK_SEA_GREEN, 5)
	#newScoreLabel("Brienne", Color.INDIAN_RED, 5)
