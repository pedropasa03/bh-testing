"""
This module contains the `Camera` class, which is used to store the information
of a camera.
"""
from dataclasses import dataclass, field

import numpy as np

from ._utils import rotation_matrix


@dataclass
class Camera:
    """
    Class containig camera infomation.
    
    Attributes
    ----------
    resolution : np.ndarray
        Two element array with the form [width, height].

    angle_y : float
        Camera angle around the y axis.

    angle_z : float
        Camera angle around the z axis.

    focal_length : float
        Focal length of the camera.

    origin : np.ndarray
        Origin of the camera.
    """
    resolution: np.ndarray
    angle_y: float
    angle_z: float
    focal_length: float
    origin: np.ndarray
    rotation_matrix: np.ndarray = field(init=False)

    def __post_init__(self):
        self.rotation_matrix = rotation_matrix(self.angle_y, self.angle_z)
    
    @classmethod
    def orbit(
        cls,
        resolution: np.ndarray,
        angle_y: float,
        angle_z: float,
        focal_lenght: float,
        camera_distance: float,
    ):
        inv_rotation_matrix = np.linalg.inv(rotation_matrix(angle_y, angle_z))
        origin = np.dot(
            inv_rotation_matrix,
            np.array([-camera_distance, 0.0, 0.0]),
        )
        
        return cls(
            resolution=resolution,
            angle_y=angle_y,
            angle_z=angle_z,
            focal_length=focal_lenght,
            origin=origin,
        )
