from bh_testing import *
import numpy as np

DEGREES = np.pi / 180.0

bh = SchwarzschildBlackHole(radius=1.0)

disk = Disk(
    inner_radius=3.0,
    outer_radius=10.0,
    thickness=0.1,
    texture=ORANGE_DISK
)

camera = Camera.orbit(
    resolution=np.array([2000, 2000]),
    angle_y=-10*DEGREES,
    angle_z=0*DEGREES,
    focal_length=5.0,
    camera_distance=50.0
)

scene = Scene(bh, disk, camera, PINK_BG)

img = scene.render()
img.show()