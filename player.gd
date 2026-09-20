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


func get_state_dict():
	return {
		'state': state,
		'points': upgradePoints,
		'current': {'bow': equipment['bow'], 'arrow': equipment['arrow'], 'armor': equipment['armor']},
		'upgrades': {'bow': equipment_upgrades['bow'], 'arrow': equipment_upgrades['arrow'], 'armor': equipment_upgrades['armor']},
	}


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
	if Net.is_client:
		return
	velocity = velocity_move + velocity_knock
	velocity_knock *= .97
	if velocity_knock.length() < 5:
		velocity_knock = Vector2.ZERO
	move_and_slide()

func set_knockback(kb):
	velocity_knock = kb

const MOVE_SCALE = 16.0 # what a fully tilted controlpad joystick used to send

var drawing = false

# move: direction with length <= 1, aim: angle the bow points, draw: is the
# string held back. Releasing draw shoots.
func set_net_input(move: Vector2, aim: float, draw: bool):
	if controllable:
		velocity_move = move.limit_length(1.0) * MOVE_SCALE * speedMultiplier
	bow_angle = aim
	$Bow.rotation = aim
	if draw or move.length() == 0:
		$Eyes.set_direction(aim)
	else:
		$Eyes.set_direction(move.angle())
	if draw and not drawing:
		$Bow.pull_back(isDead)
	elif drawing and not draw:
		notTaught()
	drawing = draw


# kind: 'bow' | 'arrow' | 'armor' | 'skip'
func handle_upgrade(kind):
	if upgradePoints > 0:
		if kind != "skip":
			if kind not in equipment_upgrades or equipment_upgrades[kind] == "nothing":
				return
			upgradeHandler(kind)
		upgradePoints -= 1
	if upgradePoints <= 0:
		upgradePoints = 0
		state = "playing"
		playerReady()
	else:
		randomizeUpgradeOptions()


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
	Net.play($HurtSound)
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
		Net.play($DrinkSound)
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
	drawing = false
	$Bow.release(true)
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
	Net.event(["fx", "death", global_position, playerColor])
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

