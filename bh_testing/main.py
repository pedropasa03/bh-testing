"""
This modules contains a sample `main` function to render some example
images.
"""
from bh_testing import *
import numpy as np

DEGREES = np.pi/180.0

def main():
    # Image 1
    bh = BlackHole(
        radius=5.0,
        inner_radius=None,
        outer_radius=None,
        thickness=None,
        texture=None
    )
    camera = Camera(
        resolution=[2000,2000],
        angle_y=0,
        angle_z=0,
        focal_length=1,
        origin=[-50.0, 0.0, 0.0]
    )
    scene = BlackHoleScene(bh, camera, LINES_BG)

    img = scene.render()
    img.save("examples/front.png")

    # Image 2
    bh = BlackHole(
        radius=5.0,
        inner_radius=15.0,
        outer_radius=40.0,
        thickness=1.0,
        texture=ORANGE_DISK
    )
    camera = Camera.orbit(
        resolution=[1920,1080],
        angle_y=-5*DEGREES,
        angle_z=0,
        focal_length=1,
        camera_distance=100.0
    )
    scene = BlackHoleScene(bh, camera, PINK_BG)

    img = scene.render()
    img.save("examples/disk.png")

    # Image 3
    bh = BlackHole(
        radius=5.0,
        inner_radius=15.0,
        outer_radius=80.0,
        thickness=2.0,
        texture=ORANGE_DISK
    )
    camera = Camera(
        resolution=[1920,1080],
        angle_y=-4*DEGREES,
        angle_z=0.5*DEGREES,
        focal_length=5,
        origin=[-750.0, -55.0, 55.0]
    )
    scene = BlackHoleScene(bh, camera, ORIENTED_BG)

    img = scene.render()
    img.save("examples/not_centered.png")

    # Image 4
    bh = BlackHole(
        radius=5.0,
        inner_radius=15.0,
        outer_radius=125.0,
        thickness=1.0,
        texture=ORANGE_DISK
    )
    camera = Camera.orbit(
        resolution=[1920,1080],
        angle_y=-3*DEGREES,
        angle_z=0,
        focal_length=40,
        camera_distance=6000
    )
    scene = BlackHoleScene(bh, camera, MULTICOLOR_BG)

    img = scene.render()
    img.save("examples/fov.png")

if __name__ == "__main__":
    main()

