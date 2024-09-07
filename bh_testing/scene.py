"""
This module contains the `Scene` class, which is used to store the information
of a scene and render it.
"""
from dataclasses import dataclass, field

import moderngl
from PIL import Image

from ._utils import get_shader, to_PIL_image
from .black_hole import BlackHole
from .camera import Camera
from .texture import Texture


@dataclass
class Scene:
    """
    A class containig information of a scene.
    
    Attributes
    ----------
    black_hole : BlackHole
        The black hole in the center.

    camera : Camera
        The camera from which to render.
        
    background_texture : Texture
        The texture that will be projected on the background.
    """
    black_hole: BlackHole
    camera: Camera
    background_texture: Texture
    ctx: moderngl.Context = field(init=False)
    computer_shader: moderngl.ComputeShader = field(init=False)

    def __post_init__(self):
        self.ctx = moderngl.create_context(standalone=True)

    def set_uniform(self, u_name, u_value) -> None:
        """
        Set a uniform in the compute shader.

        Parameters
        ----------
        u_name : str
            The name of the uniform.

        u_value : Any
            The value of the uniform.
        """
        try:
            self.computer_shader[u_name] = u_value
        except KeyError:
            raise ValueError(f"Uniform {u_name} not found in the compute shader")

    def load_texture(
        self,
        texture: Texture,
        nearest: bool,
        channel: int,
    ) -> None:
        """
        Load a texture into the shader.

        Parameters
        ----------
        texture : Texture
            The texture to load.

        nearest : bool
            Whether to use nearest neighbor interpolation.

        channel : int
            The channel to load the texture into.
        """
        texture = texture.add_texture(self.ctx)
        if nearest:
            texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
        texture.use(channel)

    def render(self) -> Image.Image:
        raise NotImplementedError(
            "This method must be implemented by a subclass."
        )


@dataclass
class BlackHoleScene(Scene):
    """
    A class to render a scene with a black hole.
    """
    def __post_init__(self):
        super().__post_init__()
        computer_shader_source = get_shader("black_hole.glsl").read_text()

        self.ctx.compute_shader(computer_shader_source)

    def render(self) -> Image.Image:
        """
        Render the scene with the black hole.
        
        Returns
        -------
        Image.Image
            The rendered image.
        """
        # Scene uniforms
        self.set_uniform('show_disk', self.black_hole.has_disk()) 
        self.load_texture(self.background_texture, False, 1)

        # Camera uniforms
        self.set_uniform('camera_origin', self.camera.origin)
        self.set_uniform('resolution', self.camera.resolution)
        self.set_uniform('rotation_matrix', self.camera.rotation_matrix.flatten())
        self.set_uniform('focal_length', self.camera.focal_length)

        # Disk uniforms
        if (self.black_hole.has_disk()):
            self.set_uniform('disk_inner_radius', self.black_hole.inner_radius)
            self.set_uniform('disk_outer_radius', self.black_hole.outer_radius)
            self.set_uniform('disk_half_thickness', 0.5*self.black_hole.thickness)
            self.load_texture(self.black_hole.texture, True, 2)

        # Black hole uniforms
        self.set_uniform('bh_radius', self.black_hole.radius)

        # Create the output texture
        output_texture = self.ctx.texture(self.camera.resolution, 4, dtype='f4')
        output_texture.bind_to_image(0, read=False, write=True)

        # Run the compute shader
        self.compute_shader.run(self.camera.resolution[0] // 30, self.camera.resolution[1] // 30)

        pil_image = to_PIL_image(output_texture, self.camera.resolution)

        return pil_image
