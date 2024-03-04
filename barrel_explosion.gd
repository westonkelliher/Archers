extends GPUParticles2D


func _ready():
	if Autoloader.mainScene != null:
		#$ref.visible = false
		return
	self.position = Vector2(200, 200)
	emitting = true
	one_shot = false
