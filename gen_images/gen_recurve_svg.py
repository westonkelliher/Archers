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


# Note: 0 angles mean straight up and down, positive angles mean outward and negative angle mean inward
class RecurveDef:
    def __init__(self, wing_len, wing_angle, bend_mag, bend_angle,
                 attach_depth, attach_mag, attach_angle, handle_len=30,
                 handle_dist=100, thickness=30, height=400, push=0, pull=0):
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


def couple_str(v):
    return str(v.x) + "," + str(v.y)



# Create a new SVG drawing
DWG = svgwrite.Drawing("bow.svg", size=('600px', '600px'))

def draw_bow(bow, offset=Vector2(0,0)):
    # note: we will draw from attach out to the tip
    #
    wing_ratio = bow.wing_len*4 / bow.height
    #
    # calculate control points
    top_bend = BASEXY + Vector2(bow.push, -bow.height/2) + offset
    top_tip = move_vector(top_bend, -90+bow.wing_angle, bow.wing_len)
    top_attach = BASEXY + Vector2(bow.attach_depth, -bow.handle_len) + offset
    top_attach_control = move_vector(top_attach, -90+bow.attach_angle, bow.attach_mag)
    top_bend_control = move_vector(top_bend, 90-bow.bend_angle, bow.bend_mag)
    top_wing_control = move_vector(top_bend, 270-bow.bend_angle, bow.bend_mag*wing_ratio)
    #
    bottom_bend = BASEXY + Vector2(bow.push, bow.height/2) + offset
    bottom_tip = move_vector(bottom_bend, 90-bow.wing_angle, bow.wing_len)
    bottom_attach = BASEXY + Vector2(bow.attach_depth, + bow.handle_len) + offset
    bottom_attach_control = move_vector(bottom_attach, 90-bow.attach_angle, bow.attach_mag)
    bottom_bend_control = move_vector(bottom_bend, -90+bow.bend_angle, bow.bend_mag)
    bottom_wing_control = move_vector(bottom_bend, -270+bow.bend_angle, bow.bend_mag*wing_ratio)
    #
    string_mid = BASEXY + Vector2(-bow.pull, 0) + offset
    
    # Draw bow string
    string_path_str = ("M " + couple_str(top_bend) +
                " L " + couple_str(string_mid) +
                " L " + couple_str(bottom_bend)
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
                        stroke_linecap='round')
    bottom_outline = DWG.path(d=bottom_path_str,
                        stroke="rgb(0, 0, 0)",
                        fill="none",
                        stroke_width=bow.thickness+LINE_THICKNESS*2, 
                        stroke_linecap='round')

    top_staff = DWG.path(d=top_path_str,
                        stroke="rgb(220, 130, 75)",
                        fill="none",
                        stroke_width=bow.thickness,
                        stroke_linecap='round')
    bottom_staff = DWG.path(d=bottom_path_str,
                        stroke="rgb(220, 130, 75)",
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
                      stroke="rgb(120, 100, 100)",
                      fill="none",
                      stroke_width=bow.thickness)
    DWG.add(handle)
    
    

def pushed_bow(b):
    return RecurveDef(wing_len, wing_angle, bend_mag, bend_angle,
                 attach_depth, attach_mag, attach_angle, handle_len=30,
                      handle_dist=100, height=b.height-15, push=b.ush+25, pull=b.pull+25):
    b.angle+3, b.bend_len, b.curve_len+7, thickness=b.thickness,
                  height=b.height-15, push=b.push+25, pull=b.pull+25)

def p_pushed_bow(b, p):
    return BowDef(b.angle+0.12*p, b.bend_len, b.curve_len+0.28*p, thickness=b.thickness,
                  height=b.height-0.6*p, push=b.push+p, pull=b.pull+p)


# draw dat
bow_a = RecurveDef(wing_len=20, wing_angle=20, bend_mag=70, bend_angle=0,
                   attach_depth=110, attach_mag=170, attach_angle=0,
                   handle_len=0, height=430)

draw_bow(bow_a, Vector2(0, 0))


# Save the drawing
name = "Short_Bow_I"
DWG.save()
cairosvg.svg2png(url='./bow.svg', write_to='./temp.png')

image = Image.open('./temp.png')
blurred = image.filter(ImageFilter.GaussianBlur(2))

blurred.save('./' + name + '.png')
