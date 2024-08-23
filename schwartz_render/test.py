from objects import *

disk_texture = Image.open("assets/disk.png")
bg_texture = Image.open("assets/grid.png")

cam = Camera.orbit(angle_y=-5*DEGREES)
bh = BlackHole()
disk = Disk(texture=disk_texture)
scene = Scene(cam, bh, disk, bg_texture)

img = scene.render()
img.show()
img.save("bh.png")