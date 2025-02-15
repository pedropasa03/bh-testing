"""
This module contains the `Disk` class, which is used to store the information
of an accretion disk.
"""
from dataclasses import dataclass

from .texture import Texture


@dataclass
class Disk:
    """
    Class that stores the parameters of an accretion disk.

    Attributes
    ----------
    inner_radius: float
        The inner radius of the accretion disk.

    outer_radius: float
        The outer radius of the accretion disk.

    thickness: float
        The thickness of the accretion disk.

    texture: Texture
        The texture of the accretion disk.
    """
    inner_radius: float
    outer_radius: float
    thickness: float
    texture: Texture