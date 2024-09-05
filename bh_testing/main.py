from objects import *


def to_radians(degrees):
    return degrees * np.pi / 180

disk_texture = Image.open("assets/disk.png")
bg_texture = Image.open("assets/grid.png")

cam = Camera.orbit(angle_y=to_radians(-5))
bh = BlackHole()
disk = Disk(texture=disk_texture)
scene = Scene(cam, bh, disk, bg_texture)

img = scene.render()
img.show()
img.save("bh.png")
