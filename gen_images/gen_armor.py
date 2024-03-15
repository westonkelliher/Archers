import copy
import svgwrite
import cairosvg
from PIL import Image, ImageFilter
import pygame
import math

from pygame.math import Vector2 

LINE_THICKNESS = 20
SHOULDER_DIST = 100
BASEXY = Vector2(250, 150)

def move_vector(v1, degrees, dist):
    angle = math.radians(degrees)
    delta_x = math.cos(angle) * dist
    delta_y = math.sin(angle) * dist
    delta_vector = pygame.math.Vector2(delta_x, delta_y)
    new_vector = v1 + delta_vector
    return new_vector


def couple_str(v):
    return str(v.x) + "," + str(v.y)

offset = BASEXY + Vector2(SHOULDER_DIST, 0)


def right_flection(p):
    return p*0.5 + BASEXY + Vector2(SHOULDER_DIST, 0)

def left_flection(p):
    q = Vector2(0,0)
    q.x = -p.x
    q.y = p.y
    return q*0.5 + BASEXY - Vector2(SHOULDER_DIST, 0)

def squinch(p, x_s, y_s, x_t, y_t):
    q = Vector2(0, 0)
    q.x = p.x*x_s + x_t
    q.y = p.y*y_s + y_t
    return q


#### Drawing ####
def make_path_str(path_points):
    p = path_points
    return ("M " + couple_str(p[0]) +
            " C " + couple_str(p[4]) + (
                " " + couple_str(p[5]) + " " + couple_str(p[1])) +
            " L " + couple_str(p[2]) + 
            " L " + couple_str(p[3]) + 
            " C " + couple_str(p[7]) + (
                " " + couple_str(p[6]) + " " + couple_str(p[0])) 
            )
def make_highlight_str(path_points):
    p = path_points
    return ("M " + couple_str(p[0]) +
            " C " + couple_str(p[4]) + (
                " " + couple_str(p[5]) + " " + couple_str(p[1])) +
            " L " + couple_str(p[2])
            )


def add_plate(dwg, path_spec, color, highlight):
    path_str = make_path_str(path_spec)
    highlight_str = make_highlight_str(path_spec)
    outline = dwg.path(d = path_str,
                         stroke = 'rgb(0, 0, 0)',
                         stroke_width = LINE_THICKNESS*3,
                         stroke_linecap = 'round', stroke_linejoin = 'round')
    path = dwg.path(d = path_str,
                      stroke = color,
                      stroke_width = LINE_THICKNESS,
                      stroke_linecap = 'round', stroke_linejoin = 'round',
                      fill = color)
    highlight = dwg.path(d = highlight_str,
                         stroke = highlight,
                         stroke_width = LINE_THICKNESS/2,
                         stroke_linecap = 'round', stroke_linejoin = 'round',
                         fill = color)
    dwg.add(outline)
    dwg.add(path)
    dwg.add(highlight)
    

def save_out(dwg, name):
    dwg.save()
    cairosvg.svg2png(url='./armor.svg', write_to='./temp.png')
    image = Image.open('./temp.png')
    image.save('../controlpad_test_server/controller/resources/equipment/' + name + '.png')
    blurred = image.filter(ImageFilter.GaussianBlur(2))
    blurred.save('../images/equipment/' + name + '.png')
    
def draw_basic(path_spec, color, highlight, name):
    DWG = svgwrite.Drawing("armor.svg", size=('500px', '300px'))
    r_q = [right_flection(p) for p in path_spec]
    l_q = [left_flection(p) for p in path_spec]
    add_plate(DWG, r_q, color, highlight)
    add_plate(DWG, l_q, color, highlight)
    save_out(DWG, name)


def draw_doubled(path_spec, color, highlight, name):
    DWG = svgwrite.Drawing("armor.svg", size=('500px', '300px'))
    sq_a = lambda p: squinch(p, 0.7, 1.1, 30, 10)
    sq_b = lambda p: squinch(p, 1.25, 0.65, 0, -30)
    r_q_a = [right_flection(sq_a(p)) for p in path_spec]
    r_q_b = [right_flection(sq_b(p)) for p in path_spec]
    l_q_a = [left_flection(sq_a(p)) for p in path_spec]
    l_q_b = [left_flection(sq_b(p)) for p in path_spec]
    add_plate(DWG, r_q_a, color, highlight)
    add_plate(DWG, r_q_b, color, highlight)
    add_plate(DWG, l_q_a, color, highlight)
    add_plate(DWG, l_q_b, color, highlight)
    save_out(DWG, name)

    
def draw_tripled(path_spec, color, highlight, name):
    DWG = svgwrite.Drawing("armor.svg", size=('500px', '300px'))
    sq_a = lambda p: squinch(p, 0.45, 1.3, 30, 50)
    sq_b = lambda p: squinch(p, 0.75, 0.9, 20, 20)
    sq_c = lambda p: squinch(p, 1.25, 0.5, 0, -30)
    r_q_a = [right_flection(sq_a(p)) for p in path_spec]
    r_q_b = [right_flection(sq_b(p)) for p in path_spec]
    r_q_c = [right_flection(sq_c(p)) for p in path_spec]
    l_q_a = [left_flection(sq_a(p)) for p in path_spec]
    l_q_b = [left_flection(sq_b(p)) for p in path_spec]
    l_q_c = [left_flection(sq_c(p)) for p in path_spec]
    add_plate(DWG, r_q_a, color, highlight)
    add_plate(DWG, r_q_b, color, highlight)
    add_plate(DWG, r_q_c, color, highlight)
    add_plate(DWG, l_q_a, color, highlight)
    add_plate(DWG, l_q_b, color, highlight)
    add_plate(DWG, l_q_c, color, highlight)
    save_out(DWG, name)
    
    
#### Spec ####
C_LEATHER = 'rgb(160, 115, 55)'
C_LEATHER_LIGHT = 'rgb(170, 125, 65)'
C_LEATHER_DARK = 'rgb(130, 90, 45)'
C_IRON = 'rgb(160, 160, 160)'
C_IRON_LIGHT = 'rgb(200, 200, 200)'
C_IRON_DARK = 'rgb(120, 120, 120)'
C_CFIBER = 'rgb(60, 60, 60)'
C_CFIBER_LIGHT = 'rgb(80, 80, 80)'
C_CFIBER_DARK = 'rgb(30, 30, 30)'
C_RED = 'rgb(45, 35, 35)'
C_RED_LIGHT = 'rgb(120, 60, 60)'


a_pinch = Vector2(-100, 0) 
a_bumper = Vector2(90, 20)
a_spike = Vector2(95, 70)
a_notch = Vector2(0, 70)
a_pinch_top_control = move_vector(a_pinch, -85, 115) 
a_bumper_top_control = move_vector(a_bumper, -90, 120)
a_pinch_bottom_control = move_vector(a_pinch, 15, 40)
a_notch_side_control = move_vector(a_notch, -100, 25)

a_path_spec = [a_pinch, a_bumper, a_spike, a_notch,
             a_pinch_top_control, a_bumper_top_control,
             a_pinch_bottom_control, a_notch_side_control]
    
draw_basic(a_path_spec, C_LEATHER, C_LEATHER_LIGHT, 'Armor_I')
draw_basic(a_path_spec, C_IRON, C_IRON_LIGHT, 'Armor_II')
draw_doubled(a_path_spec, C_IRON, C_IRON_LIGHT, 'Armor_III')
draw_doubled(a_path_spec, C_CFIBER, C_CFIBER_LIGHT, 'Armor_IV')


b_pinch = Vector2(-100, -50) 
b_bumper = Vector2(80, 0)
b_spike = Vector2(140, 105)
b_notch = Vector2(5, 90)
b_pinch_top_control = move_vector(b_pinch, -10, 70) 
b_bumper_top_control = move_vector(b_bumper, -150, 50)
b_pinch_bottom_control = move_vector(b_pinch, 80, 70)
b_notch_side_control = move_vector(b_notch, -160, 0)

b_path_spec = [b_pinch, b_bumper, b_spike, b_notch,
             b_pinch_top_control, b_bumper_top_control,
             b_pinch_bottom_control, b_notch_side_control]
    
draw_basic(b_path_spec, C_IRON, C_IRON_LIGHT, 'Heavy_Armor_I')
draw_doubled(b_path_spec, C_IRON, C_IRON_LIGHT, 'Heavy_Armor_II')
draw_tripled(b_path_spec, C_IRON, C_IRON_LIGHT, 'Heavy_Armor_III')
draw_tripled(b_path_spec, C_CFIBER, C_CFIBER_LIGHT, 'Heavy_Armor_IV')
draw_tripled(b_path_spec, C_RED, C_RED_LIGHT, 'Heavy_Armor_V')


c_pinch = Vector2(90, -50) 
c_bumper = Vector2(0, 60)
c_spike = Vector2(-50, 70)
c_notch = Vector2(-100, -50)
c_pinch_top_control = move_vector(c_pinch, 150, 40) 
c_bumper_top_control = move_vector(c_bumper, -60, 60)
c_pinch_bottom_control = move_vector(c_pinch, -100, 40)
c_notch_side_control = move_vector(c_notch, -80, 100)

c_path_spec = [c_pinch, c_bumper, c_spike, c_notch,
             c_pinch_top_control, c_bumper_top_control,
             c_pinch_bottom_control, c_notch_side_control]
    
draw_basic(c_path_spec, C_LEATHER, C_LEATHER_DARK, 'Light_Armor_I')
draw_basic(c_path_spec, C_IRON_LIGHT, C_IRON, 'Light_Armor_II')
draw_doubled(c_path_spec, C_IRON_LIGHT, C_IRON, 'Light_Armor_III')
draw_doubled(c_path_spec, C_CFIBER_LIGHT, C_CFIBER_DARK, 'Light_Armor_IV')
draw_tripled(c_path_spec, C_RED_LIGHT, C_RED, 'Light_Armor_V')
