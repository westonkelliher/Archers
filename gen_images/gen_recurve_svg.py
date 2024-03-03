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


class RecurveDef:
    def __init__(self, wing_len, wing_angle, curve_len, curve_angle,
                 attach_len, attach_angle, handle_len=40, handle_dist=100, thickness=30,
                 height=400, push=0, pull=0):
        self.wing_len = wing_len
        self.wing_angle = wing_angle
        self.curve_len = curve_len
        self.curve_angle = curve_angle
        self.attach_len = attach_len
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
DWG = svgwrite.Drawing("bow.svg", size=('1800px', '600px'))

def draw_bow(bow, offset=Vector2(0,0)):
    # calculate control points
    top_curve = BASEXY + Vector2(bow.push, -bow.height/2) + offset
    top_wing = move_vector(top_end, 90+bow.wing_angle, bow.wing_len)
    top_attach = move_vector(top_end, 90+bow.angle, bow.bend_len)
    top_curve_control = move_vector(top_end, 90+bow.angle, bow.wing_len)
    top_wing_control = move_vector(top_end, 90+bow.angle, bow.wing_len)
    top_attach_control = move_vector(top_bend, 90+bow.angle, bow.curve_len*2)
    #
    bottom_end = BASEXY + Vector2(bow.push, bow.height/2) + offset
    bottom_bend = move_vector(bottom_end, -90+bow.angle, bow.bend_len)
    bottom_control = move_vector(bottom_bend, -90+bow.angle, bow.curve_len/2)
    #
    string_mid = BASEXY + Vector2(-bow.pull, 0) + offset
    
    # Draw bow string
    path_str = ("M " + couple_str(top_end) +
                " L " + couple_str(string_mid) +
                " L " + couple_str(bottom_end)
                )
    bow_string = DWG.path(d=path_str,
                          stroke="rgb(0, 0, 0)",
                          fill="none",
                          stroke_width=LINE_THICKNESS,
                          stroke_linejoin='round')
    DWG.add(bow_string)
    
    # Draw bow curve
    path_str = ( "M " + couple_str(top_end) +
                " L " + couple_str(top_bend) +
                " C " + couple_str(top_control) + (
                    " " + couple_str(bottom_control) + " " + couple_str(bottom_bend)) +
                " L " + couple_str(bottom_end)
                )
    
    bow_outline = DWG.path(d=path_str,
                        stroke="rgb(0, 0, 0)",
                        fill="none",
                        stroke_width=bow.thickness+LINE_THICKNESS*2, 
                        stroke_linecap='round')
    bow_main = DWG.path(d=path_str,
                        stroke="rgb(220, 130, 75)",
                        fill="none",
                        stroke_width=bow.thickness,
                        stroke_linecap='round')
    DWG.add(bow_outline)
    DWG.add(bow_main)


def pushed_bow(b):
    return BowDef(b.angle+3, b.bend_len, b.curve_len+7, thickness=b.thickness,
                  height=b.height-15, push=b.push+25, pull=b.pull+25)

def p_pushed_bow(b, p):
    return BowDef(b.angle+0.12*p, b.bend_len, b.curve_len+0.28*p, thickness=b.thickness,
                  height=b.height-0.6*p, push=b.push+p, pull=b.pull+p)


# draw dat
bow_a = BowDef(70, 10, 150, height=420, thickness=40)
bow_b = p_pushed_bow(bow_a, 30)
bow_c = p_pushed_bow(bow_a, 55)

draw_bow(bow_a, Vector2(100, 0))
draw_bow(bow_b, Vector2(700, 0))
draw_bow(bow_c, Vector2(1300, 0))

# Save the drawing
DWG.save()
cairosvg.svg2png(url='./bow.svg', write_to='./temp.png')

image = Image.open('./temp.png')
blurred = image.filter(ImageFilter.GaussianBlur(2))

blurred.save('./bow.png')
