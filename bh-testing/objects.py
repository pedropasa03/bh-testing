import numpy as np
import moderngl
from PIL import Image

DEGREES = np.pi / 180.0

def rotate_y(angle):
    return np.array([
        [np.cos(angle), 0, np.sin(angle)],
        [0, 1, 0],
        [-np.sin(angle), 0, np.cos(angle)]
    ])

def rotate_z(angle):
    return np.array([
        [np.cos(angle), -np.sin(angle), 0],
        [np.sin(angle), np.cos(angle), 0],
        [0, 0, 1]
    ])

def to_PIL_image(output_texture, size):
    data = output_texture.read()
    image = np.frombuffer(data, dtype=np.float32).reshape((size[1], size[0], 4))

    # Convert to 8-bit per channel and create a PIL image
    total_image = np.clip(image * 255, 0, 255).astype(np.uint8)
    pil_image = Image.fromarray(total_image)
    return pil_image

class Camera:
    """
    Class containig camera infomation.
    ...
    Attributes
    ----------
    resolution : np.ndarray
        Tuple in the form  [width, height].

    angle_y : float
        Camera angle around the y axis.

    angle_z : float
        Camera angle around the z axis.

    focal_length : float
        Focal length of the camera.

    origin : np.ndarray
        Origin of the camera
    """
    def __init__(
            self,
            resolution: np.ndarray = np.array([1920, 1080]),
            angle_y: float = 0.0,
            angle_z: float = 0.0,
            focal_lenght: float = 1.0,
            origin:np.ndarray = np.array([-100.0,0.0,0.0])
    ):
        self.resolution = resolution
        self.angle_y = angle_y
        self.angle_z = angle_z
        self.origin = origin
        self.focal_length = focal_lenght
        self.rotation_matrix = np.dot(rotate_y(angle_y), rotate_z(angle_z))
    
    @classmethod
    def orbit(
        cls,
        resolution: np.ndarray = np.array([1920, 1080]),
        angle_y: float = 0.0,
        angle_z: float = 0.0,
        focal_lenght: float = 1.0,
        camera_distance: float = 100.0
    ):
        cam = Camera(resolution, angle_y, angle_z, focal_lenght)
        cam.origin = np.dot(np.linalg.inv(cam.rotation_matrix), np.array([-camera_distance, 0.0, 0.0]))
        return cam


class BlackHole:
    """
    A class containig information of a Schwartzschild black hole.
    ...
    Attributes
    ----------
    radius : float
    The radius of the black hole.
    """
    def __init__(self, radius: float = 5.0):
        self.radius = radius

class Disk:
    """
    A class containig information of an accretion disk.
    ...
    Attributes
    ----------
    inner_radius : float
        The inner radius of the disk.

    outer_radius : float
        The outer radius of the disk.

    thickness : float
        The thickness of the disk.
        
    texture : Image.Image
        The texture that will be projected on the disk.
    """
    def __init__(
            self,
            inner_radius: float  = 15.0,
            outer_radius: float = 40.0,
            thickness: float = 1.0,
            texture: Image.Image = None
    ):
        self.inner_radius = inner_radius
        self.outer_radius = outer_radius
        self.thickness = thickness
        self.texture = texture

class Scene:
    """
    A class containig information of a scene.
    ...
    Attributes
    ----------
    camera : Camera
        The camera from which to render.

    black_hole : BlackHole
        The black hole in the center.

    disk : Disk
        The accretion disk.
        
    background_texture : Image.Image
        The texture that will be projected on the background.
    """
    def __init__(
            self,
            camera: Camera,
            black_hole: BlackHole,
            disk: Disk = None,
            background_texture: Image.Image = None
    ):
        self.camera = camera
        self.black_hole = black_hole
        self.disk = disk
        self.background_texture = background_texture
        self.show_disk = not disk is None

        # Initiate
        self.ctx = moderngl.create_context(standalone=True)

        compute_shader_source = open("shaders/compute_shader.glsl").read()
        self.compute_shader = self.ctx.compute_shader(compute_shader_source)

    def set_uniform(self, u_name, u_value):
        try:
            self.compute_shader[u_name] = u_value
        except KeyError:
            pass

    def load_texture(self, image: Image.Image, nearest: bool, channel: int):
        image_data = image.convert("RGBA").tobytes()
        texture = self.ctx.texture(image.size, 4, image_data)
        if nearest:
            texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
        texture.use(channel)

    def render(self) -> Image.Image:
        ## Set uniform values ##
        # Scene uniforms
        self.set_uniform('show_disk', self.show_disk) 
        self.load_texture(self.background_texture, False, 1)

        # Camera uniforms
        self.set_uniform('camera_origin', self.camera.origin)
        self.set_uniform('resolution', self.camera.resolution)
        self.set_uniform('rotation_matrix', self.camera.rotation_matrix.flatten())
        self.set_uniform('focal_length', self.camera.focal_length)

        # Disk uniforms
        if (self.show_disk):
            self.set_uniform('disk_inner_radius', self.disk.inner_radius)
            self.set_uniform('disk_outer_radius', self.disk.outer_radius)
            self.set_uniform('disk_half_thickness', 0.5*self.disk.thickness)
            self.load_texture(self.disk.texture, True, 2)

        # Black hole uniforms
        self.set_uniform('bh_radius', self.black_hole.radius)

        # Create the output texture
        output_texture = self.ctx.texture(self.camera.resolution, 4, dtype='f4')
        output_texture.bind_to_image(0, read=False, write=True)

        # Run the compute shader
        self.compute_shader.run(self.camera.resolution[0] // 30, self.camera.resolution[1] // 30)

        pil_image = to_PIL_image(output_texture, self.camera.resolution)

        return pil_image