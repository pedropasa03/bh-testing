import moderngl
from bh_testing._utils import to_PIL_image
from PIL import Image
from pathlib import Path
import numpy as np

ctx = moderngl.create_context(standalone=True)
compute_shader_source = Path("bh_testing/shaders/kerr.glsl").read_text()
compute_shader = ctx.compute_shader(compute_shader_source)


# Set uniforms
image = Image.open("bh_testing/assets/lines_bg.png")
image_data = image.convert("RGBA").tobytes()

moderngl_texture = ctx.texture(image.size, 4, image_data)

# moderngl_texture.filter = (moderngl.NEAREST, moderngl.NEAREST)
moderngl_texture.use(1)

# Create the output texture
size = [1024, 1024]
compute_shader['resolution'] = size
compute_shader['a'] = 0.99

output_texture = ctx.texture(size, 4, dtype='f4')
output_texture.bind_to_image(0, read=False, write=True)

# Run the compute shader
compute_shader.run(1 + size[0]//32, 1 + size[1]//32)

ctx.finish()

pil_image = to_PIL_image(output_texture, size)
pil_image.show()
pil_image.save("test.png")
