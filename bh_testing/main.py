"""
This modules contains a sample `main` function to render some example
images.
"""
"""
This modules contains a sample `main` function to render some example
images.
"""
from bh_testing import *

def main():
    bh = BlackHole(
        radius=5.0,
        inner_radius=15.0,
        outer_radius=40.0,
        thickness=1.0,
        texture=ORANGE_DISK
    )

    camera = Camera(
        resolution=[1000,1000],
        angle_y=0,
        angle_z=0,
        focal_length=1,
        origin=[-100.0, 0.0, 0.0]
    )
    scene = BlackHoleScene(bh,camera, PINK_BG)

    img = scene.render()
    img.show()

if __name__ == "__main__":
    main()

