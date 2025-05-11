"""
This modules contains a sample `main` function to render some example
images.
"""
from bh_testing import *
import numpy as np

DEGREES = np.pi/180.0

def main():
    # Image 1
    bh = SchwarzschildBlackHole(radius=2.0)
    camera = Camera(
        resolution=[2048,2048],
        angle_y=0,
        angle_z=0,
        focal_length=1.5,
        origin=[-40.0, 0.0, 0.0]
    )
    scene = Scene(space_time=bh, disk=None, camera=camera, background_texture=LINES_BG)

    img = scene.render()
    img.save("examples/front.png")

    # Image 2
    bh = SchwarzschildBlackHole(radius=5.0)
    disk = Disk(
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
    scene = Scene(space_time=bh, disk=disk, camera=camera, background_texture=PINK_BG)

    img = scene.render()
    img.save("examples/disk.png")

    # Image 3
    bh = SchwarzschildBlackHole(radius=5.0)
    disk = Disk(
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
    scene = Scene(space_time=bh, disk=disk, camera=camera, background_texture=ORIENTED_BG)

    img = scene.render()
    img.save("examples/not_centered.png")

    # Image 4
    bh = SchwarzschildBlackHole(radius=5.0)
    disk = Disk(
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
    scene = Scene(space_time=bh, disk=disk, camera=camera, background_texture=MULTICOLOR_BG)

    img = scene.render()
    img.save("examples/fov.png")

if __name__ == "__main__":
    main()

