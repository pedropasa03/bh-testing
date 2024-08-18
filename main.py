import moderngl
import numpy as np
from PIL import Image

DEGREES = np.pi /180.0

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

ctx = moderngl.create_context(standalone=True)

# Load and compile the compute shader
compute_shader_code = open("programs/compute_shader.glsl").read()
try:
    compute_shader = ctx.compute_shader(compute_shader_code)
except Exception as e:
    print(f"Error compiling shader: {e}")
    exit(1)

# Create the output texture
size = (1920, 1080)
output_texture = ctx.texture(size, 4, dtype='f4')
output_texture.bind_to_image(0, read=True, write=True)
i=0

for t in np.linspace(-np.pi*0.5, np.pi*0.5, 60*4):
    # Constants
    k = 0.5+0.5*np.sin(t)
    camera_center = np.array([-600*(1-k) - 20*k, 0, 0])
    #camera_distance = 500.0
    angle_y = 0*DEGREES
    angle_z = 0*DEGREES
    rotation_matrix = np.dot(rotate_y(angle_y),rotate_z(angle_z))
    focal_length = 1.0

    # Set uniform values
    compute_shader['resolution'].value = size
    compute_shader['camera_distance'].value = np.linalg.norm(camera_center)#camera_distance
    compute_shader['rotation_matrix'].value = rotation_matrix.flatten()
    compute_shader['camera_origin'].value = camera_center#np.dot(np.linalg.inv(rotation_matrix), np.array([-camera_distance, 0.0, 0.0])) 
    #compute_shader['show_ring'].value = True
    #compute_shader['use_sphere_texture'].value = False
    compute_shader['focal_length'].value = focal_length

    # Run the compute shader
    compute_shader.run(size[0] // 30, size[1] // 30)

    # Now, output_texture contains the result, which you can use or save as an image
    data = output_texture.read()
    image = np.frombuffer(data, dtype=np.float32).reshape((size[1], size[0], 4))

    # Convert to 8-bit per channel and create a PIL image
    total_image = np.clip(image * 255, 0, 255).astype(np.uint8)
    pil_image = Image.fromarray(total_image)

    # Save the image using PIL
    pil_image.save(f'out{i}.png')
    i+=1
pil_image.show()