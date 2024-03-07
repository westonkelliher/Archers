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

	func new(drawTime = 0.4, chargeTime = 4.0, basePower = 25.0, maxPower = 50.0,
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
	'Bow_II':  BowSpec.new(drawTime=0.32, chargeTime=3.2, basePower=25.0, maxPower = 55.0)
	'Bow_III': BowSpec.new(drawTime=0.25, chargeTime=2.5, basePower=30.0, maxPower = 55.0),
	'Bow_IV':  BowSpec.new(drawTime=0.20, chargeTime=2.0, basePower=30.0, maxPower = 60.0),
	'Bow_V':   BowSpec.new(drawTime=0.15, chargeTime=1.5, basePower=35.0, maxPower = 60.0),
	#
	'Short_Bow_I':   BowSpec.new(drawTime=0.15, chargeTime=2.0, basePower=30.0, maxPower = 42.0,
		                         baseLift=4.0, maxLift=7.0),
	'Short_Bow_II':  BowSpec.new(drawTime=0.12, chargeTime=1.5, basePower=32.0, maxPower = 44.0,
		                         baseLift=4.0, maxLift=7.0),
	'Short_Bow_III': BowSpec.new(drawTime=0.09, chargeTime=1.1, basePower=34.0, maxPower = 46.0,
		                         baseLift=4.0, maxLift=7.0),
	'Short_Bow_IV':  BowSpec.new(drawTime=0.07, chargeTime=0.8, basePower=36.0, maxPower = 48.0,
		                         baseLift=4.0, maxLift=7.0),
	'Short_Bow_V':   BowSpec.new(drawTime=0.05, chargeTime=0.6, basePower=38.0, maxPower = 50.0,
		                         baseLift=4.0, maxLift=7.0),
	#
	'Long_Bow_I':   BowSpec.new(drawTime=0.5, chargeTime=4.0, basePower=25.0, maxPower = 60.0,
		                        baseLift=8.0, maxLift=16.0),
	'Long_Bow_II':  BowSpec.new(drawTime=0.5, chargeTime=3.5, basePower=30.0, maxPower = 70.0,
		                        baseLift=10.0, maxLift=16.0),
	'Long_Bow_III': BowSpec.new(drawTime=0.5, chargeTime=3.0, basePower=40.0, maxPower = 80.0,
		                        baseLift=12.0, maxLift=16.0),
	'Long_Bow_IV':  BowSpec.new(drawTime=0.5, chargeTime=2.5, basePower=50.0, maxPower = 90.0,
		                        baseLift=14.0, maxLift=16.0),
	'Long_Bow_V':   BowSpec.new(drawTime=0.4, chargeTime=2.0, basePower=60.0, maxPower = 100.0,
		                        baseLift=16.0, maxLift=16.0),
		
	
######## Armor ########
class ArmorSpec:
	var healthBonus: int  
	var speedBonus:  float # measured as fraction of base speed
	var ability:     EntityAbility

	func new(healthBonus = 0, speedBonus = 0, ability = null):
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
	'Basic_Armor_I':   ArmorSpec.new(healthBonus=20)
	'Basic_Armor_II':  ArmorSpec.new(healthBonus=50)
	'Basic_Armor_III': ArmorSpec.new(healthBonus=80)
	'Basic_Armor_IV':  ArmorSpec.new(healthBonus=120)
	#
	'Heavy_Armor_I':   ArmorSpec.new(healthBonus=40, speedBonus=-0.12)
	'Heavy_Armor_II':  ArmorSpec.new(healthBonus=85, speedBonus=-0.14)
	'Heavy_Armor_III': ArmorSpec.new(healthBonus=130, speedBonus=-0.16)
	'Heavy_Armor_IV':  ArmorSpec.new(healthBonus=185, speedBonus=-0.18)
	'Heavy_Armor_V' :  ArmorSpec.new(healthBonus=240, speedBonus=-0.20)
	#
	'Light_Armor_I':   ArmorSpec.new(healthBonus=10, speedBonus=0.10)
	'Light_Armor_II':  ArmorSpec.new(healthBonus=25, speedBonus=0.15)
	'Light_Armor_III': ArmorSpec.new(healthBonus=40, speedBonus=-0.22)
	'Light_Armor_IV':  ArmorSpec.new(healthBonus=55, speedBonus=0.30)
	'Light_Armor_V':   ArmorSpec.new(healthBonus=70, speedBonus=0.45)
	

######## Arrows ########
class ArrowSpec:
	var baseDamage: int 
	var drag:       float       # how much the arrow slows in flight (fraction per
                                # second)
	var effect:     EntityEffect

	func new(baseDamage = 20, drag = 0.1, effect = null):
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
	
	func new(effectStartFunc = null, effectOngoingFunc = create_timeout_func(1000),
		     effectEndFunction = null):
		self.effectStartFunc = effectStartFunc
		self.effectOngoingFunc = effectOngoingFunc
		self.effectEndFunc = effectEndFunc

	
	
## Arrow Effects ##
func create_timeout_func(total_millis):
	return func (elapsed_millis):
	    if ellapsed_millis >= total_millis:
	        return true
	    return false
	
var end_ice_effect = func (victim):
	victim.speedModifier = 1.0
	
var start_ice_effect_I = func (victim):
	victim.speedModifier = 0.5
var start_ice_effect_II = func (victim):
	victim.speedModifier = 0.4
var start_ice_effect_III = func (victim):
	victim.speedModifier = 0.3
	
var IceEffect_I =   EntityEffect(start_ice_effect_I,   create_timeout_func(1000), end_ice_effect)
var IceEffect_II =  EntityEffect(start_ice_effect_II,  create_timeout_func(2000), end_ice_effect)
var IceEffect_III = EntityEffect(start_ice_effect_III, create_timeout_func(3000), end_ice_effect)
	
var ARROW_SPECS = {
	'Arrow_I':   ArrowSpec.new(),
	'Arrow_II':  ArrowSpec.new(baseDamage=30)
	'Arrow_III': ArrowSpec.new(baseDamage=45)
	'Arrow_IV':  ArrowSpec.new(baseDamage=60)
	'Arrow_V':   ArrowSpec.new(baseDamage=75)
	#
	'Heavy_Arrow_I':   ArrowSpec.new(baseDamage=45, drag=0.4)
	'Heavy_Arrow_II':  ArrowSpec.new(baseDamage=65, drag=0.5)
	'Heavy_Arrow_III': ArrowSpec.new(baseDamage=90, drag=0.58)
	'Heavy_Arrow_IV':  ArrowSpec.new(baseDamage=120, drag=0.65)
	'Heavy_Arrow_V' :  ArrowSpec.new(baseDamage=160, drag=0.7)
	#
	'Ice_Arrow_I':   ArrowSpec.new(baseDamage=20, effect=IceEffect_I)
	'Ice_Arrow_II':  ArrowSpec.new(baseDamage=30, effect=IceEffect_I)
	'Ice_Arrow_III': ArrowSpec.new(baseDamage=35, effect=IceEffect_II)
	'Ice_Arrow_IV':  ArrowSpec.new(baseDamage=45, effect=IceEffect_II)
	'Ice_Arrow_V':   ArrowSpec.new(baseDamage=50, effect=IceEffect_III)
	
		
	


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
