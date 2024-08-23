from classes import *
import time

disk_texture = Image.open("assets/rip2.png")
bg_texture = Image.open("assets/bg.png")

cam = Camera.orbit(angle_y=-5*DEGREES, angle_z=0.5,camera_distance=750, focal_lenght=5.0)
bh = BlackHole(6)
disk = Disk(outer_radius=0,texture=disk_texture)

scene = Scene(cam, bh, disk, bg_texture)
img = scene.render()
img.show()