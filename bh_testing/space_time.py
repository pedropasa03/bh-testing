"""
This module defines the `BlackHole` class, which is used to store the
parameters of a black hole.
"""
from dataclasses import dataclass, field


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

    def is_schwarzschild(self) -> bool:
        return self.spin == 0.0


@dataclass   
class SchwarzschildBlackHole(SpaceTime):
    """
    Class that stores the parameters of a schwarzschild black hole.

    Attributes
    ----------
    radius: float
        The radius of the black hole.
    """
    radius: float
    spin: float = field(init=False)
    hair: float = field(init=False)

    def __post_init__(self):
        self.spin = 0.0

    def is_schwarzschild(self) -> bool:
        return True
    
    def is_kerr(self) -> bool:
        return False



@dataclass   
class KerrBlackHole(SpaceTime):
    """
    Class that stores the parameters of a kerr black hole.

    Attributes
    ----------
    radius: float
        The radius of the black hole.

    spin: float
        The spin parameter of the black hole.
    """
    radius: float
    spin: float

    def is_schwarzschild(self) -> bool:
        return self.spin == 0.0
    
    def is_kerr(self) -> bool:
        return self.spin != 0.0
