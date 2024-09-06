import numpy as np
from PIL import Image


def rotate_y(angle):
    return np.array([
        [np.cos(angle), 0, np.sin(angle)],
        [0, 1, 0],
        [-np.sin(angle), 0, np.cos(angle)]
    ])

def rotate_z(angle):
    return np.array([
        [np.cos(angle), -np.sin(angle), 0],
        [np.sin(angle), np.cos(angle), 0],
        [0, 0, 1]
    ])

def rotation_matrix(angle_y, angle_z):
    return np.dot(
        rotate_y(angle_y),
        rotate_z(angle_z)
    )

def to_PIL_image(output_texture, size):
    data = output_texture.read()
    image = np.frombuffer(data, dtype=np.float32).reshape((size[1], size[0], 4))

    # Convert to 8-bit per channel and create a PIL image
    total_image = np.clip(image * 255, 0, 255).astype(np.uint8)
    pil_image = Image.fromarray(total_image)
    return pil_image
