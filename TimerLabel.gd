extends Label

var countdown_duration = 3  # Adjust as needed
var countdown_timer = countdown_duration
var countdown_timer_label = countdown_timer
var complete = false

func _ready():
	position = get_viewport().size / 2
	update_timer_text()

func _process(delta):
	if not complete:
		countdown_timer -= delta
		countdown_timer_label = snapped(countdown_timer, 0.01)
		if countdown_timer < 1:
			countdown_timer_label = "GO!"
			complete = true
			# Handle timer completion here
	update_timer_text()

func update_timer_text():
	text = str(countdown_timer_label)
