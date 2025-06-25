#version 430 core
precision highp float;  

// Constants
const float PI = 3.14159265358979323846;

// Scene settings
const float DELTA = 0.0005;
const int MAX_ITER = 100000;

// Output texture
layout(local_size_x = 32, local_size_y = 32) in;
layout(binding = 0, rgba32f) uniform image2D img_output;

// Uniforms
uniform bool show_disk;

uniform vec3  camera_origin;
uniform float focal_length;
uniform vec2  resolution;
uniform mat3  rotation_matrix;

uniform float disk_inner_radius;
uniform float disk_outer_radius;
uniform float disk_half_thickness;

uniform float bh_radius;

// External textures
layout(binding = 1) uniform sampler2D background_texture;
layout(binding = 2) uniform sampler2D disk_texture;

// Calculate inverses
float inverse_sky_distance = 1.0 / 1e3;
float distance_inverse = 1.0 / length(camera_origin);
float bh_inverse_radius = 1.0 / bh_radius;
float inverse_inner_radius = 1.0 / disk_inner_radius;
float inverse_outer_radius = 1.0 / disk_outer_radius;


// Functions
vec3 RotateByAxis(vec3 vector, vec3 axis_rotation, float phi)
{
    return vector * cos(phi) + cross(axis_rotation, vector) * sin(phi) + axis_rotation * (1.0-cos(phi)) * dot(axis_rotation, vector);
}

vec3 GetFinalVector(vec3 vector, vec3 axis_rotation, float phi, float u, float du)
{
    vec3 d_num = -vector * sin(phi) + cross(axis_rotation, vector) * cos(phi) + axis_rotation * sin(phi) * dot(axis_rotation, vector);

    return ((d_num * u) - (RotateByAxis(vector, axis_rotation, phi) * du / u)) / (u * u);

}

float VectorAngle(vec3 vector1, vec3 vector2)
{
    return acos(dot(vector1, vector2) / (length(vector1)*length(vector2)));
}

/*Calculate angle between two unit vectors*/
float UnitVectorAngle(vec3 vector1, vec3 vector2)
{
    return acos(dot(vector1, vector2));
}

vec2 DiskUV(vec3 point, float inner_radius, float outer_radius)
{
    return vec2((length(point.xy)-inner_radius)/(outer_radius-inner_radius), 0.5 + atan(point.y, point.x)/(2.0*PI));
}

vec2 SphereUV(vec3 direction)
{
    direction = normalize(direction);
    float u = 0.5 + atan(direction.y, direction.x)/(2.0*PI);
    float v = 0.5 + asin(direction.z)/PI;

    return vec2(u, v);
}

float aspect_ratio = resolution.x / resolution.y;
vec3 ShootRay(vec2 uv)
{
    uv = 2.0*uv - 1.0;
    uv.y /= aspect_ratio;

    vec3 ray_direction = normalize(vec3(focal_length, uv));
    return rotation_matrix * ray_direction;
}

vec2 schwarzschild(vec2 y)
{
    float u = y.x;
    float du = y.y;

    float d2u = 1.5*bh_radius*u*u - u;

    return vec2(du, d2u);
}

// ------------------------------- MAIN ------------------------------- //
void main()
{
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(pixelCoord) / resolution;
    vec3 ray_direction = ShootRay(uv);

    vec3 unit_camera_origin = normalize(camera_origin);
    float alpha = UnitVectorAngle(-unit_camera_origin, ray_direction);
    vec3 axis_rotation = normalize(cross(-unit_camera_origin, ray_direction));

    vec4 px_color = vec4(0,0,0,1);

    // Trace geodesic
    float phi = 0.0;
    vec2 y    = vec2(distance_inverse, distance_inverse / tan(alpha));

    vec3 final_direction;

    for (int i = 0; i < MAX_ITER; i++)
    {
        vec2 k1 = DELTA * schwarzschild(y);
        vec2 k2 = DELTA * schwarzschild(y + 0.5 * k1);
        vec2 k3 = DELTA * schwarzschild(y + 0.5 * k2);
        vec2 k4 = DELTA * schwarzschild(y + k3);
        
        y += (k1 + 2.0 * (k2 + k3) + k4) / 6.0;
        phi += DELTA;

        float u = y[0];
        float du = y[1];

        final_direction = RotateByAxis(unit_camera_origin, axis_rotation, phi) / u;

        // Ray escapes to infinity
        if (u < inverse_sky_distance)
        {
            final_direction = GetFinalVector(unit_camera_origin, axis_rotation, phi, u, du);

            vec2 sphere_uv = SphereUV(final_direction);
            px_color = texture(background_texture, sphere_uv);
            break;
        }
        // Ray falls to disk
        if (show_disk)
        {
            if (abs(final_direction.z) < disk_half_thickness && u < inverse_inner_radius && u > inverse_outer_radius)
            {
                if ((abs(u-inverse_inner_radius) < 0.0001 || abs(u-inverse_outer_radius)<0.0001) && (abs(final_direction.z-disk_half_thickness) < 0.1 || abs(final_direction.z+disk_half_thickness) < 0.1))
                    px_color = vec4(0.9,0.2,0.1,1);
                else
                {
                    vec2 disk_uv = DiskUV(final_direction, disk_inner_radius, disk_outer_radius);
                    px_color = texture(disk_texture, disk_uv);
                }
                break;
            }
        }
        // Ray falls to black hole
        if (u > bh_inverse_radius)
        {
            px_color = vec4(0,0,0,1);
            break;
        }
    }
    imageStore(img_output, pixelCoord, px_color);
}
