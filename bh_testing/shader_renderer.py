"""
This module contains the base class `ShaderRenderer`, used by the `Scene` class
to render the scene using a shader.

We also define one subclass, `BlackHoleRenderer`, which is used to render a
black hole scene.
"""
from dataclasses import dataclass
from pathlib import Path

import moderngl
from PIL import Image

from ._utils import to_PIL_image, get_shader
from .texture import Texture
from .black_hole import BlackHole
from .camera import Camera


@dataclass
class ShaderRenderer:
    """
    A class to render a scene using a shader.

    Attributes
    ----------
    ctx : moderngl.Context
        The ModernGL context.

    compute_shader : moderngl.ComputeShader
        The compute shader used to render the scene.
    """
    ctx: moderngl.Context
    computer_shader: moderngl.ComputeShader

    @classmethod
    def from_source(cls, shader_source: str) -> "ShaderRenderer":
        """
        Create a `ShaderRenderer` from a shader source.

        Parameters
        ----------
        shader_source : str
            The source of the shader.

        Returns
        -------
        ShaderRenderer
            The shader renderer.
        """
        ctx = moderngl.create_context(standalone=True)
        compute_shader = ctx.compute_shader(shader_source)

        return cls(
            ctx=ctx, 
            computer_shader=compute_shader
        )

    @classmethod
    def from_file(cls, shader_file: str | Path) -> "ShaderRenderer":
        """
        Create a `ShaderRenderer` from a shader file.

        Parameters
        ----------
        shader_file : str | Path
            The path to the shader file.

        Returns
        -------
        ShaderRenderer
            The shader renderer.
        """
        shader_file = Path(shader_file)
        shader_source = shader_file.read_text()

        return cls.from_source(shader_source)

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
        texture = texture.get_texture(self.ctx)
        if nearest:
            texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
        texture.use(channel)

    def render(self) -> Image.Image:
        """
        Render the scene.

        Returns
        -------
        Image.Image
            The rendered image.
        """
        raise NotImplementedError("The render method must be implemented in a subclass")


@dataclass
class BlackHoleRenderer(ShaderRenderer):
    """
    A subclass of `ShaderRenderer` to render a black hole scene.
    """
    def __init__(self):
        super().from_file(get_shader("black_hole.glsl"))

    def render(
        self,
        black_hole: BlackHole,
        camera: Camera,
        background_texture: Texture,
    ) -> Image.Image:
        """
        Render the scene.

        Returns
        -------
        Image.Image
            The rendered image.
        """
        # Scene uniforms
        self.set_uniform('show_disk', black_hole.has_disk()) 
        self.load_texture(background_texture, False, 1)

        # Camera uniforms
        self.set_uniform('camera_origin', camera.origin)
        self.set_uniform('resolution', camera.resolution)
        self.set_uniform('rotation_matrix', camera.rotation_matrix.flatten())
        self.set_uniform('focal_length', camera.focal_length)

        # Disk uniforms
        if (black_hole.has_disk()):
            self.set_uniform('disk_inner_radius', black_hole.inner_radius)
            self.set_uniform('disk_outer_radius', black_hole.outer_radius)
            self.set_uniform('disk_half_thickness', 0.5*black_hole.thickness)
            self.load_texture(black_hole.texture, True, 2)

        # Black hole uniforms
        self.set_uniform('bh_radius', black_hole.radius)

        # Create the output texture
        output_texture = self.ctx.texture(camera.resolution, 4, dtype='f4')
        output_texture.bind_to_image(0, read=False, write=True)

        # Run the compute shader
        self.compute_shader.run(camera.resolution[0] // 30, camera.resolution[1] // 30)

        pil_image = to_PIL_image(output_texture, camera.resolution)

        return pil_image
