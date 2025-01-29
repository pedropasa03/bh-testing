"""
This module defines the `BlackHole` class, which is used to store the
parameters of a black hole.
"""
from dataclasses import dataclass


@dataclass
class SpaceTime:
    """
    Class that stores the parameters of a space-time.

    Attributes
    ----------
    radius: float
        The radius of the black hole.
    spin: float
        The spin parameter of the black hole.
    hair: float
        The hair parameter of the space surrounding the black hole.
    """
    radius: float
    spin: float
    hair: float

    def is_schwartzchild(self) -> bool:
        return self.spin == 0.0 and self.hair == 0.0
    
    def is_kerr(self) -> bool:
        return self.hair == 0.0


@dataclass   
class SchwarzschildBlackHole(SpaceTime):
    """
    Class that stores the parameters of a schwarzschild black hole.

    Attributes
    ----------
    radius: float
        The radius of the black hole.
    """
    def __post_init__(self):
        super().__post_init__()
        self.spin = 0.0
        self.hair = 0.0



@dataclass   
class KerrBlackHole(SpaceTime):
    def __post_init__(self):
        super().__post_init__()
        self.hair = 0.0