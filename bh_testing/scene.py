"""
This module contains the `Scene` class, which is used to store the information
of a scene and render it.
"""
from dataclasses import dataclass

from PIL import Image

from .black_hole import BlackHole
from .camera import Camera
from .texture import Texture
from .shader_renderer import ShaderRenderer


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
    shader_renderer: ShaderRenderer

    def render(self) -> Image.Image:
        return self.shader_renderer.render(
            black_hole=self.black_hole,
            camera=self.camera,
            background_texture=self.background_texture,
        )
