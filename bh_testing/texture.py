"""
This module contains the base class for texture objects.

Furthermore, it defines some texture constants that can be used without
the need of using custom ones.
"""
from dataclasses import dataclass
from pathlib import Path

from PIL import Image
import moderngl

from ._utils import get_asset


@dataclass
class Texture:
    """
    Base class for textures.

    You can create a custom texture by subclassing this class and
    implementing the `get_texture` method.

    Attributes
    ----------
    image_path: str | Path
        Path to the texture image.
    """
    image_path: str | Path

    def get_texture(self, ctx: moderngl.Context) -> moderngl.Texture:
        """
        Returns a PIL Image object from the texture image path.
        """
        image = Image.open(self.image_path)
        image_data = image.convert("RGBA").tobytes()

        return ctx.texture(image.size, 4, image_data)


PINK_BG = Texture(get_asset("pink_bg.png"))
"""
Texture object for a pink background.
"""
MULTICOLOR_BG = Texture(get_asset("multicolor_bg.png"))
"""
Texture object for a multicolor background.
"""
ORIENTED_BG = Texture(get_asset("oriented_bg.png"))
"""
Texture object for an oriented (and multicolor) background.
"""
ORANGE_DISK = Texture(get_asset("orange_disk.png"))
"""
Texture object for an orange disk.
"""
