import svgwrite
import cairosvg
from PIL import Image, ImageFilter
import pygame
import math

from pygame.math import Vector2 

LINE_THICKNESS = 20
BASEX = 100
BASEY = 300
BASEXY = Vector2(BASEX, BASEY)


def move_vector(v1, degrees, dist):
    angle = math.radians(degrees)
    delta_x = math.cos(angle) * dist
    delta_y = math.sin(angle) * dist
    delta_vector = pygame.math.Vector2(delta_x, delta_y)
    new_vector = v1 + delta_vector
    return new_vector

C_MAPLE =    "rgb(220, 130, 75)"
C_GRAY = "rgb(110, 100, 100)"

# Note: 0 angles mean straight up and down, positive angles mean outward and negative angle mean inward
class RecurveDef:
    def __init__(self, wing_len, wing_angle, bend_mag, bend_angle,
                 attach_depth, attach_mag, attach_angle, handle_len=30,
                 handle_dist=100, thickness=30, height=400, push=0, pull=0,
                 staff_color=C_MAPLE, handle_color=C_GRAY, backstring=False):
        self.wing_len = wing_len
        self.wing_angle = wing_angle
        self.bend_mag = bend_mag
        self.bend_angle = bend_angle
        self.attach_depth = attach_depth
        self.attach_mag = attach_mag
        self.attach_angle = attach_angle
        #
        self.handle_len = handle_len
        self.thickness = thickness
        self.height = height
        self.push = push
        self.pull = pull
        #
        self.staff_color = staff_color
        self.handle_color = handle_color
        #
        self.backstring = backstring


def couple_str(v):
    return str(v.x) + "," + str(v.y)




# Create a new SVG drawing
DWG = None

def draw_bow(bow, offset=Vector2(0,0)):
    # note: we will draw from attach out to the tip
    #
    wing_ratio = bow.wing_len*4 / bow.height
    #
    # calculate control points
    top_bend = BASEXY + Vector2(bow.push, -bow.height/2) + offset
    top_tip = move_vector(top_bend, -90+bow.wing_angle, bow.wing_len)
    top_attach = BASEXY + Vector2(bow.attach_depth+bow.push*1.2, -bow.handle_len) + offset
    top_attach_control = move_vector(top_attach, -90+bow.attach_angle, bow.attach_mag)
    top_bend_control = move_vector(top_bend, 90-bow.bend_angle, bow.bend_mag)
    top_wing_control = move_vector(top_bend, 270-bow.bend_angle, bow.bend_mag*wing_ratio)
    #
    bottom_bend = BASEXY + Vector2(bow.push, bow.height/2) + offset
    bottom_tip = move_vector(bottom_bend, 90-bow.wing_angle, bow.wing_len)
    bottom_attach = BASEXY + Vector2(bow.attach_depth+bow.push*1.2, + bow.handle_len) + offset
    bottom_attach_control = move_vector(bottom_attach, 90-bow.attach_angle, bow.attach_mag)
    bottom_bend_control = move_vector(bottom_bend, -90+bow.bend_angle, bow.bend_mag)
    bottom_wing_control = move_vector(bottom_bend, -270+bow.bend_angle, bow.bend_mag*wing_ratio)
    #
    string_mid = BASEXY + Vector2(-bow.pull, 0) + offset
    
    # Draw bow string
    string_offset = Vector2(0, 0)
    if bow.backstring:
        string_offset = Vector2(-bow.thickness/2, 0)
    string_path_str = ("M " + couple_str(top_bend+string_offset) +
                " L " + couple_str(string_mid+string_offset) +
                " L " + couple_str(bottom_bend+string_offset)
                )
    bow_string = DWG.path(d=string_path_str,
                          stroke="rgb(0, 0, 0)",
                          fill="none",
                          stroke_width=LINE_THICKNESS,
                          stroke_linejoin='round')
    DWG.add(bow_string)

    # Draw bow curve
    top_path_str = ( "M " + couple_str(bottom_attach) +
                     "L " + couple_str(top_attach) +
                     " C " + couple_str(top_attach_control) + (
                         " " + couple_str(top_bend_control) + " " + couple_str(top_bend)) +
                     " C " + couple_str(top_wing_control) + (
                         " " + couple_str(top_tip) + " " + couple_str(top_tip)) 
                    )
    bottom_path_str = ( "M " + couple_str(top_attach) +
                        "L " + couple_str(bottom_attach) +
                     " C " + couple_str(bottom_attach_control) + (
                         " " + couple_str(bottom_bend_control) + " " + couple_str(bottom_bend)) +
                     " C " + couple_str(bottom_wing_control) + (
                         " " + couple_str(bottom_tip) + " " + couple_str(bottom_tip)) 
                    )
    
    top_outline = DWG.path(d=top_path_str,
                        stroke="rgb(0, 0, 0)",
                        fill="none",
                        stroke_width=bow.thickness+LINE_THICKNESS*2, 
                           stroke_linecap='round',
                          stroke_linejoin='round')
    bottom_outline = DWG.path(d=bottom_path_str,
                        stroke="rgb(0, 0, 0)",
                        fill="none",
                        stroke_width=bow.thickness+LINE_THICKNESS*2, 
                              stroke_linecap='round',
                          stroke_linejoin='round')

    top_staff = DWG.path(d=top_path_str,
                         stroke=bow.staff_color,
                         fill="none",
                         stroke_width=bow.thickness,
                         stroke_linecap='round')
    bottom_staff = DWG.path(d=bottom_path_str,
                            stroke=bow.staff_color,
                            fill="none",
                            stroke_width=bow.thickness,
                            stroke_linecap='round')
    DWG.add(top_outline)
    DWG.add(bottom_outline)
    DWG.add(top_staff)
    DWG.add(bottom_staff)

    # Draw handle
    handle_path_str = ("M " + couple_str(top_attach) +
                       " L " + couple_str(bottom_attach)
                       )
    handle = DWG.path(d=handle_path_str,
                      stroke=bow.handle_color,
                      fill="none",
                      stroke_width=bow.thickness)
    DWG.add(handle)
    
    

    
def p_pushed_bow(b, p):
    return RecurveDef(wing_len=b.wing_len*(1+p/300), wing_angle=b.wing_angle-0.3*p,
                      bend_mag=b.bend_mag, bend_angle=b.bend_angle+0.3*p,
                      attach_depth=b.attach_depth+0.3*p, attach_mag=b.attach_mag*0.9,
                      attach_angle=b.attach_angle, handle_len=b.handle_len,
                      height=b.height-1.0*p, push=b.push+p, pull=b.pull+p,
                      thickness=b.thickness,
                      staff_color=b.staff_color, handle_color=b.handle_color)


def generate_spritesheet(bow_def, name):
    global DWG
    DWG = svgwrite.Drawing("bow.svg", size=('1800px', '600px'))
    bow_b = p_pushed_bow(bow_def, 30)
    bow_c = p_pushed_bow(bow_def, 55)

    draw_bow(bow_def, Vector2(100, 0))
    draw_bow(bow_b, Vector2(700, 0))
    draw_bow(bow_c, Vector2(1300, 0))
    
    # Save the drawing
    DWG.save()
    cairosvg.svg2png(url='./bow.svg', write_to='./temp.png')
    
    image = Image.open('./temp.png')
    blurred = image.filter(ImageFilter.GaussianBlur(2))
    
    blurred.save('./' + name + '.png')
    

C_MAPLE =    "rgb(220, 130, 75)"
C_ELM =      "rgb(210, 150, 95)"
C_MAHAGONY = "rgb(155, 95, 65)"
C_IVORY =    "rgb(210, 180, 150)"
C_CFIBER =   "rgb(80, 80, 80)"
#
C_GRAY = "rgb(110, 100, 100)"
C_BLACK = "rgb(50, 50, 50)"
C_RED = "rgb(170, 90, 70)"

#### draw long bows ####
bow_I = RecurveDef(wing_len=0, wing_angle=0, bend_mag=65, bend_angle=70,
                   attach_depth=125, attach_mag=155, attach_angle=0,
                   handle_len=0, height=450, thickness=30)
generate_spritesheet(bow_I, "Bow_I")

bow_II = RecurveDef(wing_len=0, wing_angle=30, bend_mag=60, bend_angle=0,
                    attach_depth=100, attach_mag=120, attach_angle=0,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_ELM)
generate_spritesheet(bow_II, "Bow_II")

bow_III = RecurveDef(wing_len=0, wing_angle=40, bend_mag=60, bend_angle=0,
                     attach_depth=90, attach_mag=120, attach_angle=10,
                     handle_len=30, height=430, thickness=30,
                     staff_color=C_MAHAGONY, handle_color=C_BLACK)
generate_spritesheet(bow_III, "Bow_III")

bow_IV = RecurveDef(wing_len=0, wing_angle=10, bend_mag=60, bend_angle=20,
                    attach_depth=70, attach_mag=120, attach_angle=20,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_IVORY, handle_color=C_BLACK)
generate_spritesheet(bow_IV, "Bow_IV")

bow_V = RecurveDef(wing_len=0, wing_angle=30, bend_mag=60, bend_angle=20,
                   attach_depth=55, attach_mag=140, attach_angle=20,
                   handle_len=30, height=450, thickness=30,
                   staff_color=C_CFIBER, handle_color=C_RED)
generate_spritesheet(bow_V, "Bow_V")

    
#### draw short bows ####
shortbow_I = RecurveDef(wing_len=20, wing_angle=20, bend_mag=70, bend_angle=0,
                   attach_depth=110, attach_mag=170, attach_angle=0,
                   handle_len=0, height=430, thickness=30)
generate_spritesheet(shortbow_I, "Shortbow_I")

shortbow_II = RecurveDef(wing_len=30, wing_angle=30, bend_mag=60, bend_angle=0,
                    attach_depth=100, attach_mag=120, attach_angle=0,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_ELM)
generate_spritesheet(shortbow_II, "Shortbow_II")

shortbow_III = RecurveDef(wing_len=35, wing_angle=40, bend_mag=60, bend_angle=0,
                     attach_depth=90, attach_mag=120, attach_angle=10,
                     handle_len=30, height=430, thickness=30,
                     staff_color=C_MAHAGONY, handle_color=C_BLACK)
generate_spritesheet(shortbow_III, "Shortbow_III")

shortbow_IV = RecurveDef(wing_len=40, wing_angle=10, bend_mag=60, bend_angle=20,
                    attach_depth=70, attach_mag=120, attach_angle=20,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_IVORY, handle_color=C_BLACK)
generate_spritesheet(shortbow_IV, "Shortbow_IV")

shortbow_V = RecurveDef(wing_len=20, wing_angle=30, bend_mag=60, bend_angle=20,
                   attach_depth=55, attach_mag=140, attach_angle=20,
                   handle_len=30, height=450, thickness=30,
                   staff_color=C_CFIBER, handle_color=C_RED)
generate_spritesheet(shortbow_V, "Shortbow_V")



#### draw long bows ####
longbow_I = RecurveDef(wing_len=20, wing_angle=20, bend_mag=70, bend_angle=0,
                   attach_depth=110, attach_mag=170, attach_angle=0,
                   handle_len=0, height=430, thickness=30)
generate_spritesheet(longbow_I, "Longbow_I")

longbow_II = RecurveDef(wing_len=30, wing_angle=30, bend_mag=60, bend_angle=0,
                    attach_depth=100, attach_mag=120, attach_angle=0,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_ELM)
generate_spritesheet(longbow_II, "Longbow_II")

longbow_III = RecurveDef(wing_len=35, wing_angle=40, bend_mag=60, bend_angle=0,
                     attach_depth=90, attach_mag=120, attach_angle=10,
                     handle_len=30, height=430, thickness=30,
                     staff_color=C_MAHAGONY, handle_color=C_BLACK)
generate_spritesheet(longbow_III, "Longbow_III")

longbow_IV = RecurveDef(wing_len=40, wing_angle=10, bend_mag=60, bend_angle=20,
                    attach_depth=70, attach_mag=120, attach_angle=20,
                    handle_len=30, height=430, thickness=30,
                    staff_color=C_IVORY, handle_color=C_BLACK)
generate_spritesheet(longbow_IV, "Longbow_IV")

longbow_V = RecurveDef(wing_len=20, wing_angle=30, bend_mag=60, bend_angle=20,
                   attach_depth=55, attach_mag=140, attach_angle=20,
                   handle_len=30, height=450, thickness=30,
                   staff_color=C_CFIBER, handle_color=C_RED)
generate_spritesheet(longbow_V, "Longbow_V")
