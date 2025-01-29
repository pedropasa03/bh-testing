from bh_testing import *
import numpy as np
import gc

DEGREES = np.pi / 180.0

bh = BlackHole(
    radius=5.0,
    inner_radius=None,
    outer_radius=None,
    thickness=None,
    texture=None
)
c = np.log(15000) / 100

i=402
for t in np.linspace(0, 100, 8*60)[402:]:
    camera = Camera(
        resolution=np.array([2000, 2000]),
        angle_y=-10.6429*DEGREES,
        angle_z=-10.6429*DEGREES,
        origin=np.array([-50.0, 0.0, 0.0]),
        focal_length=np.exp(c * t)
    )

    scene = BlackHoleScene(bh,camera, LINES_BG)

    img = scene.render()
    img.save(f"renders/render{i}.png")

    i += 1