extends CharacterBody2D
class_name Player

var playerID = null
var playerColor = null
var playerName = "Player"
var isDead = false
var gameScore = 0
var controllable = true
var readyUp = false
var savedPosition = null
var invulnerable = false
var unspawned : bool = false
var state = "playing"
var upgradePoints = 0

## equipment ##
var _equipment = {
	'arrow_tier': 1,
	'bow_tier': 1,
	'armor_tier': 1,
	'arrow': 'Arrow_I',
	'bow': 'Bow_I',
	'armor': 'None',
}
var equipment = _equipment.duplicate(true)

var _equipment_upgrades = {
	'arrow_tier': 2,
	'bow_tier': 2,
	'armor_tier': 2,
	'arrow': 'Arrow_II',
	'bow': 'Bow_II',
	'armor': 'Armor_I',
}
var equipment_upgrades = _equipment_upgrades.duplicate(true)


var speedMultiplier = 15
var baseSpeedMultiplier = 15

var armorHealth = 0
var health = 100
var baseHealth = 100

var arrowDamage = 20
var arrowDrag = 0
var arrowEffect = null

var knockback = Vector2.ZERO

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var arrow_scene = preload("res://arrow.tscn")
var death_explosion = preload("res://death_explosion.tscn")
var bow_angle = null

var sfx_shootBow = preload("res://audio/shootBow.mp3")

signal bow_shot(player, chargeLevel, lift)
signal bow_charge()
signal hit()

var lastPos
var velocity_move : Vector2 = Vector2.ZERO
var velocity_knock : Vector2 = Vector2.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func get_state_string():
	var player_color = self.playerColor
	var colorString = "#%x%x%xff" % [player_color.r*255, player_color.g*255, player_color.b*255]
	var state_str = "state:" + self.state
	if self.state == "playing":
		state_str += ":" + colorString
	elif self.state == "upgrading":
		state_str += ":" + colorString + ":" + str(self.upgradePoints)
		state_str +=  ":" + equipment["arrow"] + "," + equipment["bow"] + "," + equipment["armor"] 
		state_str +=  ":" + equipment_upgrades["arrow"] + "," + equipment_upgrades["bow"] + "," + equipment_upgrades["armor"] 
	#print(state_str)
	return state_str
	

func _ready():
	$Body.modulate = playerColor
	$Nametag/Label.text = playerName
	setBow(equipment['bow'])
	setArrow(equipment['arrow'])
	setArmor(equipment['armor'])
	pass # Replace with function body.

func _process(delta):
	if $Bow.charge_amount > 0:
		$Chargebar.visible = true
		$Chargebar.value = $Bow.charge_amount*100
	else:
		$Chargebar.visible = false
	
	if $Healthbar.value == $Healthbar.max_value:
		$Healthbar.visible = false
	else:
		$Healthbar.visible = true


func _physics_process(delta):
	velocity = velocity_move + velocity_knock
	velocity_knock *= .97
	if velocity_knock.length() < 5:
		velocity_knock = Vector2.ZERO
	move_and_slide()

func set_knockback(kb):
	velocity_knock = kb

func handle_controlpad_input(message: String):
	var parts = message.split(":")
	if parts[0] == "move" and controllable:
		var xy = parts[1].split(",")
		var in_vel = Vector2(float(xy[0]), float(xy[1]))
		var threshhold = 16.0;
		if in_vel.length() > threshhold:
			in_vel *= threshhold/in_vel.length()
		#var mult = 15.0;
		self.velocity_move = in_vel * speedMultiplier;
		if in_vel.length() > 0 and !$Bow.is_pulling:
			var in_angle = in_vel.angle()
			$Eyes.set_direction(in_angle)
		
		#Test
		
	elif parts[0] == "bow": #and controllable:
		# Rotation
		var xy = parts[1].split(",")
		var in_aim = Vector2(float(xy[0]), float(xy[1]))
		if in_aim.length() < 1:
			notTaught()
			return
		bow_angle = in_aim.angle() - PI
		$Bow.rotation = bow_angle
		$Eyes.set_direction(bow_angle)
		# Pullback
		var threshhold = 8.0;
		if in_aim.length() > threshhold:
			if !$Bow.is_pulling:
				$Bow.pull_back(isDead)
			#emit_signal("bow_charge")
		else:
			notTaught()
	
	elif parts[0] == "upgrade":
		if self.upgradePoints > 0:
			upgradeHandler(parts[1])
			self.upgradePoints -= 1
		if self.upgradePoints <= 0:
			self.upgradePoints = 0
			self.state = "playing"
			playerReady()
		else:
			randomizeUpgradeOptions()
		
	
	elif parts[0] == "ready":
		readyUp = true
		controllable = true
		if isDead:
			self.global_position = savedPosition
	
	elif parts[0] == "name":
		playerName = parts[1]
		$Nametag/Label.text = playerName
	
	elif parts[0] == "debug":
		print("Debug from client: " + playerID + " - " + playerName + ": " + str(parts[1]))

func playerReady():
	readyUp = true
	controllable = true
	if isDead:
		self.global_position = savedPosition

#Sets the possible upgrades for the player randomly/current equipment
func randomizeUpgradeOptions():
	equipment_upgrades['bow'] = $Equipment.setUpgradeChoice('bows', equipment['bow_tier'], equipment['bow'])
	equipment_upgrades['bow_tier'] = equipment['bow_tier']+1
	equipment_upgrades['arrow'] = $Equipment.setUpgradeChoice('arrows', equipment['arrow_tier'], equipment['arrow'])
	equipment_upgrades['arrow_tier'] = equipment['arrow_tier']+1
	equipment_upgrades['armor'] = $Equipment.setUpgradeChoice('armors', equipment['armor_tier'], equipment['armor'])
	equipment_upgrades['armor_tier'] = equipment['armor_tier']+1

func upgradeHandler(upgrade):
	if upgrade == "bow":
		equipment['bow_tier'] = equipment_upgrades['bow_tier']
		var newBowName = equipment_upgrades['bow']
		setBow(newBowName)
	#
	elif upgrade == "arrow":
		equipment['arrow_tier'] = equipment_upgrades['arrow_tier']
		var newArrowName = equipment_upgrades['arrow']
		setArrow(newArrowName)
	#
	elif upgrade == "armor":
		equipment['armor_tier'] = equipment_upgrades['armor_tier']
		var newArmorName = equipment_upgrades['armor']
		setArmor(newArmorName)

func set_equipment(bow, arrow, armor):
	setBow(bow)
	setArrow(arrow)
	setArmor(armor)

func setBow(name, overrides: Dictionary = {}):
	equipment['bow'] = name
	var bow_spec = $Equipment.BOW_SPECS[name]
	if overrides.size() > 0:
		bow_spec = $Equipment.customEquipment('bow', name, overrides)
	$Bow.draw_time = bow_spec.drawTime
	$Bow.charge_time = bow_spec.chargeTime
	$Bow.max_power = bow_spec.maxPower
	$Bow.base_power = bow_spec.basePower
	$Bow.max_lift = bow_spec.maxLift
	$Bow.base_lift = bow_spec.baseLift
	$Bow.set_graphic(equipment['bow'])

func setArrow(name, overrides: Dictionary = {}):
	equipment['arrow'] = name
	var arrow_spec = $Equipment.ARROW_SPECS[name]
	if overrides.size() > 0:
		arrow_spec = $Equipment.customEquipment('arrow', name, overrides)
	self.arrowDamage = arrow_spec.baseDamage
	self.arrowDrag = arrow_spec.drag
	$Bow.set_arrow_graphic(equipment['arrow'])

func setArmor(name, overrides: Dictionary = {}):
	equipment['armor'] = name
	var armor_spec = $Equipment.ARMOR_SPECS[name]
	if overrides.size() > 0:
		armor_spec = $Equipment.customEquipment('armor', name, overrides)
	speedMultiplier = baseSpeedMultiplier * (1 + armor_spec.speedBonus)
	$Healthbar.max_value = baseHealth + armor_spec.healthBonus
	$Healthbar/Damagebar.max_value = $Healthbar.max_value
	$Armor.texture = load("res://images/equipment/" + equipment['armor'] + ".png")


func notTaught():
	if $Bow.charge_amount > 0 and controllable:
		emit_signal("bow_shot", self, $Bow.get_power(), $Bow.get_lift())
	$Bow.release(isDead)


func _on_area_2d_body_entered(body):
	if !(body is Arrow):
		return
	if body.originPlayer != self.playerID and not invulnerable:
		playerDamaged(body.damage)
		body.hitPlayer(self)
		if body.specialProperty:
			print("This arrow has a special property")

func playerDamaged(damage, damageType = "general"):
	$HurtSound.play()
	$Healthbar/Damagebar.visible = true
	$Healthbar.visible = true
	$Healthbar.value -= damage
	Autoloader.damageNumbers(damage, $DamageNumberOrigin.global_position, damageType)
	$Healthbar/Timer.start()
	if $Healthbar.value <= 0:
		playerDeath()

func playerGainHealth(health, potion = false):
	var amountHealed = health
	var originalHealth = $Healthbar.value
	$Healthbar.value += health
	$Healthbar/Damagebar.value += health
	if $Healthbar.value == $Healthbar.max_value:
		#$Healthbar.value = $Healthbar.max_value
		#$Healthbar/Damagebar.value = $Healthbar.max_value
		amountHealed = $Healthbar.max_value - originalHealth
	if potion:
		$DrinkSound.play()
	Autoloader.damageNumbers(amountHealed, $DamageNumberOrigin.global_position, "health")


func hitstun(stun):
	controllable = false
	await get_tree().create_timer(stun).timeout
	controllable = true


func playerDeath():
	deathExplosion()
	savedPosition = self.global_position
	self.global_position = Vector2(-5000, -5000)
	if Autoloader.mainScene.multiplayerStarted:
		isDead = true
		controllable = false
		readyUp = false
		Autoloader.mainScene.winCheck()
	else:
		respawn()


func respawn():
	invulnerable = true
	await get_tree().create_timer(1.0).timeout
	modulate = Color(1, 1, 1, 0.5)
	restoreAll()
	global_position = savedPosition
	await get_tree().create_timer(5.0).timeout
	modulate = Color(1, 1, 1, 1)
	invulnerable = false

func refresh():
	$Healthbar.value = $Healthbar.max_value
	$Healthbar/Damagebar.value = $Healthbar/Damagebar.max_value
	$RoyalCrown.visible = false
	isDead = false
	readyUp = false
	invulnerable = false
	knockback = Vector2.ZERO
	velocity_knock = Vector2.ZERO
	velocity_move = Vector2.ZERO
	if $Nametag/Label.text.ends_with("★"):
		$Nametag/Label.text = playerName


func deathExplosion():
	var explosion = death_explosion.instantiate()
	explosion.global_position = self.global_position
	explosion.emitting = true
	explosion.modulate = playerColor
	#get_tree().get_root().add_child(explosion)
	Autoloader.mainScene.add_child(explosion)
	pass
	
func restoreAll():
	$Healthbar.value = $Healthbar.max_value
	$Healthbar/Damagebar.value = $Healthbar/Damagebar.max_value
	isDead = false
	readyUp = false
	gameScore = 0
	


func resetUpgrades():
	#arrowDamage = 20
	#speedMultiplier = 15
	#$Bow.draw_time = .5
	#$Bow.charge_time = 4
	#$Healthbar.max_value = 100
	#$Healthbar/Damagebar.max_value = 100
	#$Healthbar.value = 100
	#$Healthbar/Damagebar.value = 100
	
	#NOTE This is a sanity check
	speedMultiplier = baseSpeedMultiplier
	
	#Resets equipment and equipment upgrades table.
	#Should work but probably needs to be tested more
	set_equipment('Bow_I', 'Arrow_I', 'None')
	equipment = _equipment.duplicate(true)
	equipment_upgrades = _equipment_upgrades.duplicate(true)


func winner():
	$Nametag/Label.text += "★"

func _on_timer_timeout():
	#$Healthbar/Damagebar.value = $Healthbar.value
	var tween = get_tree().create_tween() 
	tween.set_parallel(true)
	tween.tween_property(
		$Healthbar/Damagebar, "value", $Healthbar.value, 0.3
	).set_ease(Tween.EASE_OUT)
	pass

func sfxManager(effect):
	$SoundEffects.stream = effect
	$SoundEffects.play()

