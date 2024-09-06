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
    inner_radius: float
        The inner radius of the accretion disk.
    outer_radius: float
        The outer radius of the accretion disk.
    thickness: float
        The thickness of the accretion disk.
    texture: Texture
        The texture of the accretion disk.
    """
    radius: float
    inner_radius: float
    outer_radius: float
    thickness: float
    texture: Texture
