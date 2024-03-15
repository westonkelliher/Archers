extends Node

## equipment ideas
# teleport arrow
# fire arrow - fire spreads by touch
# confusion arrow
# homing bow
# sequential multi shot bows
# spread multi shot
# ability to teleport to location of arrow
# charm arrow

var ALL_EQUIPMENT = {
	'arrows': {
		1: ['Arrow_I'],
		2: ['Arrow_II', 'Ice_Arrow_I', 'Heavy_Arrow_I'],
		3: ['Arrow_III', 'Ice_Arrow_II', 'Heavy_Arrow_II'],
		4: ['Arrow_IV', 'Heavy_Arrow_III'],
		5: ['Arrow_V', 'Ice_Arrow_III'],
		6: ['Ice_Arrow_IV', 'Heavy_Arrow_IV'],
	},
	'bows': {
		1: ['Bow_I'],
		2: ['Bow_II', 'Short_Bow_I', 'Long_Bow_I'],
		3: ['Bow_III', 'Short_Bow_II', 'Long_Bow_II'],
		4: ['Bow_IV', 'Long_Bow_III'],
		5: ['Bow_V', 'Short_Bow_III'],
		6: ['Short_Bow_IV', 'Long_Bow_IV'],
	},
	'armors': {
		1: ['None'],
		2: ['Light_Armor_I', 'Medium_Armor_I'],
		3: ['Heavy_Armor_I', 'Medium_Armor_II'],
		4: ['Light_Armor_II', 'Heavy_Armor_II', 'Medium_Armor_III'],
		5: ['Armor_V', 'Ice_Armor_III'],
		6: ['Ice_Armor_IV', 'Heavy_Armor_IV'],
	},
}

######## Bows ########
class BowSpec:
	var drawTime:   float
	var chargeTime: float
	var basePower:  float  # starting speed at 0 charge
	var maxPower:   float  # starting speed at full charge
	var baseLift:   float  # starting upward velocity at 0 charge
	var maxLift:    float  # starting upward velocity at full charge
	var numShots:   int
	# range is speed*f(lift) ie power*f(lift)

	func _init(drawTime = 0.4, chargeTime = 4.0, basePower = 25.0, maxPower = 50.0,
			 baseLift = 5.0, maxLift = 10.0, numShots = 1):
		self.drawTime = drawTime
		self.chargeTime = chargeTime
		self.basePower = basePower
		self.maxPower = maxPower
		self.baseLift = baseLift
		self.maxLift = maxLift
		self.numShots = numShots

var BOW_SPECS = {
	'Bow_I':   BowSpec.new(),
	'Bow_II':  BowSpec.new(0.32, 3.2, 25.0,  55.0),
	'Bow_III': BowSpec.new(0.25, 2.5, 30.0,  55.0),
	'Bow_IV':  BowSpec.new(0.20, 2.0, 30.0,  60.0),
	'Bow_V':   BowSpec.new(0.15, 1.5, 35.0,  60.0),
	#
	'Short_Bow_I':   BowSpec.new(0.15, 2.0, 30.0,  42.0,
								 4.0, 7.0),
	'Short_Bow_II':  BowSpec.new(0.12, 1.5, 32.0,  44.0,
								 4.0, 7.0),
	'Short_Bow_III': BowSpec.new(0.09, 1.1, 34.0,  46.0,
								 4.0, 7.0),
	'Short_Bow_IV':  BowSpec.new(0.07, 0.8, 36.0,  48.0,
								 4.0, 7.0),
	'Short_Bow_V':   BowSpec.new(0.05, 0.6, 38.0,  50.0,
								 4.0, 7.0),
	#
	'Long_Bow_I':   BowSpec.new(0.5, 4.0, 25.0,  60.0,
								8.0, 16.0),
	'Long_Bow_II':  BowSpec.new(0.5, 3.5, 30.0,  70.0,
								10.0, 16.0),
	'Long_Bow_III': BowSpec.new(0.5, 3.0, 40.0,  80.0,
								12.0, 16.0),
	'Long_Bow_IV':  BowSpec.new(0.5, 2.5, 50.0,  90.0,
								14.0, 16.0),
	'Long_Bow_V':   BowSpec.new(0.4, 2.0, 60.0,  100.0,
								16.0, 16.0),
}
	
######## Armor ########
class ArmorSpec:
	var healthBonus: int  
	var speedBonus:  float # measured as fraction of base speed
	var ability:     EntityAbility

	func _init(healthBonus = 0, speedBonus = 0, ability = null):
		self.healthBonus = healthBonus
		self.speedBonus = speedBonus
		self.ability = ability
		
class EntityAbility:
	var isAvailableFunc:   Callable
	var effectStartFunc:   Callable
	var effectOngoingFunc: Callable
	var effectEndFunc:     Callable

var ARMOR_SPECS = {
	'None':      ArmorSpec.new(),
	'Basic_Armor_I':   ArmorSpec.new(20),
	'Basic_Armor_II':  ArmorSpec.new(50),
	'Basic_Armor_III': ArmorSpec.new(80),
	'Basic_Armor_IV':  ArmorSpec.new(120),
	#
	'Heavy_Armor_I':   ArmorSpec.new(40, -0.12),
	'Heavy_Armor_II':  ArmorSpec.new(85, -0.14),
	'Heavy_Armor_III': ArmorSpec.new(130, -0.16),
	'Heavy_Armor_IV':  ArmorSpec.new(185, -0.18),
	'Heavy_Armor_V' :  ArmorSpec.new(240, -0.20),
	#
	'Light_Armor_I':   ArmorSpec.new(10, 0.10),
	'Light_Armor_II':  ArmorSpec.new(25, 0.15),
	'Light_Armor_III': ArmorSpec.new(40, -0.22),
	'Light_Armor_IV':  ArmorSpec.new(55, 0.30),
	'Light_Armor_V':   ArmorSpec.new(70, 0.45),
}

######## Arrows ########
class ArrowSpec:
	var baseDamage: int 
	var drag:       float       # how much the arrow slows in flight (fraction per
								# second)
	var effect:     EntityEffect

	func _init(baseDamage = 20, drag = 0.1, effect = null):
		self.baseDamage = baseDamage
		self.drag = drag
		self.effect = effect

class EntityEffect:
	#### functions are applied to the victim of the arrow
	var effectStartFunc:   Callable
	#### arrow owner passed in
	#### location of arrow passed in
	var effectOngoingFunc: Callable
	#### must return true when the effect should end, false otherwise
	var effectEndFunc:     Callable
	#
	var effectStart:       int      # instant measured in msecs since engine start
									# (get_ticks_msec)
	static func create_timeout_func(total_millis):
		return func (elapsed_millis):
			if elapsed_millis >= total_millis:
				return true
			return false
	
	func _init(effectStartFunc = null, effectOngoingFunc = create_timeout_func(1000),
			 effectEndFunction = null):
		self.effectStartFunc = effectStartFunc
		self.effectOngoingFunc = effectOngoingFunc
		self.effectEndFunc = effectEndFunc

	
	
## Arrow Effects ##
var end_ice_effect = func (victim):
	victim.speedModifier = 1.0
	
var start_ice_effect_I = func (victim):
	victim.speedModifier = 0.5
var start_ice_effect_II = func (victim):
	victim.speedModifier = 0.4
var start_ice_effect_III = func (victim):
	victim.speedModifier = 0.3
	
	
var IceEffect_I =   EntityEffect.new(start_ice_effect_I,   EntityEffect.create_timeout_func(1000), end_ice_effect)
var IceEffect_II =  EntityEffect.new(start_ice_effect_II,  EntityEffect.create_timeout_func(2000), end_ice_effect)
var IceEffect_III = EntityEffect.new(start_ice_effect_III, EntityEffect.create_timeout_func(3000), end_ice_effect)

var ARROW_SPECS = {
	'Arrow_I':   ArrowSpec.new(),
	'Arrow_II':  ArrowSpec.new(30),
	'Arrow_III': ArrowSpec.new(45),
	'Arrow_IV':  ArrowSpec.new(60),
	'Arrow_V':   ArrowSpec.new(75),
	#
	'Heavy_Arrow_I':   ArrowSpec.new(45, 0.4),
	'Heavy_Arrow_II':  ArrowSpec.new(65, 0.5),
	'Heavy_Arrow_III': ArrowSpec.new(90, 0.58),
	'Heavy_Arrow_IV':  ArrowSpec.new(120, 0.65),
	'Heavy_Arrow_V' :  ArrowSpec.new(160, 0.7),
	#
	'Ice_Arrow_I':   ArrowSpec.new(20, 0.1, IceEffect_I),
	'Ice_Arrow_II':  ArrowSpec.new(30, 0.1, IceEffect_I),
	'Ice_Arrow_III': ArrowSpec.new(35, 0.1, IceEffect_II),
	'Ice_Arrow_IV':  ArrowSpec.new(45, 0.1, IceEffect_II),
	'Ice_Arrow_V':   ArrowSpec.new(50, 0.1, IceEffect_III),
}	

	


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
