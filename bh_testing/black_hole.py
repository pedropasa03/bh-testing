"""
This module defines the `BlackHole` class, which is used to store the
parameters of a black hole.
"""
from dataclasses import dataclass

from .texture import Texture


@dataclass
class BlackHole:
    """
    Class that stores the parameters of a black hole.

    Attributes
    ----------
    radius: float
        The radius of the black hole.
    inner_radius: float | None
        The inner radius of the accretion disk.
    outer_radius: float | None
        The outer radius of the accretion disk.
    thickness: float | None
        The thickness of the accretion disk.
    texture: Texture | None
        The texture of the accretion disk.
    """
    radius: float
    inner_radius: float | None
    outer_radius: float | None
    thickness: float | None
    texture: Texture | None

    def has_disk(self):
        """
        If any of the parameters of the disk are None, then the disk is not
        present.
        """
        return all(
            [
                self.inner_radius is not None,
                self.outer_radius is not None,
                self.thickness is not None,
                self.texture is not None,
            ]
        )
