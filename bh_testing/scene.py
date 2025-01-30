"""
This module contains the `Scene` class, which is used to store the information
of a scene and render it.
"""
from dataclasses import dataclass, field

import moderngl
from PIL import Image

from ._utils import get_shader, to_PIL_image
from .space_time import SpaceTime, SchwarzschildBlackHole, KerrBlackHole
from .disk import Disk
from .camera import Camera
from .texture import Texture


@dataclass
class Scene:
    """
    A class containig information of a scene.
    
    Attributes
    ----------
    space_time : SpaceTime
        The black hole in the center.

    disk : Disk | None
        The accretion disk around the black hole.

    camera : Camera
        The camera from which to render.
        
    background_texture : Texture
        The texture that will be projected on the background.
    """
    space_time: SpaceTime
    disk: Disk | None
    camera: Camera
    background_texture: Texture
    ctx: moderngl.Context = field(init=False)
    compute_shader: moderngl.ComputeShader = field(init=False)

    def __post_init__(self):
        self.ctx = moderngl.create_context(standalone=True)
        compute_shader_source = get_shader("black_hole.glsl").read_text()
        self.compute_shader = self.ctx.compute_shader(compute_shader_source)

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
            self.compute_shader[u_name] = u_value
        except KeyError:
            raise ValueError(f"Uniform {u_name} not found in the compute shader")

    def load_texture(
        self,
        texture: Texture,
        channel: int,
    ) -> None:
        """
        Load a texture into the shader.

        Parameters
        ----------
        texture : Texture
            The texture to load.

        channel : int
            The channel to load the texture into.
        """
        moderngl_texture = texture.add_texture(self.ctx)
        if texture.nearest:
            moderngl_texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
        moderngl_texture.use(channel)

    def set_schwartzchild_uniforms(self) -> None:
            self.set_uniform('show_disk', self.disk is not None) 
            self.load_texture(self.background_texture, 1)

            # Camera uniforms
            self.set_uniform('camera_origin', self.camera.origin)
            self.set_uniform('resolution', self.camera.resolution)
            self.set_uniform('rotation_matrix', self.camera.rotation_matrix.flatten())
            self.set_uniform('focal_length', self.camera.focal_length)

            # Disk uniforms
            if (self.disk is not None):
                self.set_uniform('disk_inner_radius', self.disk.inner_radius)
                self.set_uniform('disk_outer_radius', self.disk.outer_radius)
                self.set_uniform('disk_half_thickness', 0.5*self.disk.thickness)
                self.load_texture(self.disk.texture, 2)

            # Black hole uniforms
            self.set_uniform('bh_radius', self.space_time.radius)


    def render(self) -> Image.Image:
        if not self.space_time.is_schwartzchild():
            raise NotImplementedError(
                "This scene is not yet supported."
            )
        else:
            self.set_schwartzchild_uniforms()

            # Create the output texture
            output_texture = self.ctx.texture(self.camera.resolution, 4, dtype='f4')
            output_texture.bind_to_image(0, read=False, write=True)

            # Run the compute shader
            self.compute_shader.run(1 + self.camera.resolution[0]//32, 1 + self.camera.resolution[1]//32)

            pil_image = to_PIL_image(output_texture, self.camera.resolution)

            return pil_image
