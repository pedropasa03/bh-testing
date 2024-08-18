#version 430

layout(local_size_x = 30, local_size_y = 30) in;
layout(binding = 0, rgba32f) uniform image2D img_output;

// ------------------------------- CONSTANTS ------------------------------- //
#define PI 3.14159265359

// ------------------------------- UNIFORMS ------------------------------- //
uniform vec2 resolution;
uniform float camera_distance;
uniform mat3 rotation_matrix;
uniform sampler2D ring;
uniform vec3 camera_origin;
uniform bool camera_type;
uniform bool show_ring;
uniform bool use_sphere_texture;
uniform float focal_length;


//Things we need:
const float DELTA = 0.001;
const float INVERSE_SKY_DISTANCE = 1.0 / 1e10;
const float inverse_inner_radius = 1.0 / 15.0;
const float inverse_outer_radius = 1.0 / 50.0;
const vec3 disk_normal = vec3(0, 0, 1);
const float bh_radius = 5.0;
const float bh_inverse_radius = 1.0 / bh_radius;
float distance_inverse = 1.0 / camera_distance;

// Colors
#define white vec4(1,1,1,1)
#define pink vec4(1, 0.6823, 0.7882, 1)

// ------------------------------- FUNCTIONS ------------------------------- //
vec4 gridTexture(vec2 uv, vec2 num, vec4 color1, vec4 color2)
{
	int i = int(num.x*uv.x) % int(num.x+1.0);
	int j = int(num.y*uv.y) % int(num.y+1.0);
	
    return ((i + j) % 2 == 0) ? color1 : color2;
}

/*
Rodrigues' rotation formula.
If v is a vector in R^3 and e is a unit vector rooted at the origin describing an axis
of rotation about which v is rotated by an angle θ.
*/
vec3 RotateByAxis(vec3 vector, vec3 axis_rotation, float theta)
{
    return vector * cos(theta) + cross(axis_rotation, vector) * sin(theta) + axis_rotation * (1.0-cos(theta)) * dot(axis_rotation, vector);
}

float VectorAngle(vec3 vector1, vec3 vector2)
{
	return acos(dot(vector1, vector2) / (length(vector1)*length(vector2)));
}

vec2 diskUV(vec3 point, float outer_radius, float inner_radius)
{
    return vec2((length(point.xy)-inner_radius)/(outer_radius - inner_radius), 0.5 + atan(point.y, point.x)/(2.0*PI));
}

vec2 sphereUV(vec3 direction)
{
	direction = normalize(direction);
	float u = 0.5 + atan(direction.y, direction.x)/(2.0*PI);
	float v = 0.5 + asin(direction.z)/PI;

	return vec2(u, v);
}

float aspect_ratio = resolution.x / resolution.y;
vec3 shootRay(vec2 uv)
{
    uv = 2.0*uv - 1.0;
    uv.y /= aspect_ratio;

    vec3 ray_direction = normalize(vec3(focal_length, uv));
    return rotation_matrix * ray_direction;
}

// ------------------------------- MAIN ------------------------------- //

const int MAX_ITER = 100000;

void main()
{
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(pixelCoord) / resolution;
    vec3 ray_direction = shootRay(uv);

    float alpha = VectorAngle(-camera_origin, ray_direction);
	vec3 axis_rotation = normalize(cross(-camera_origin, ray_direction));

    vec4 px_color = vec4(0,0,0,1);

    // Trace geodesic
    float phi = 0.0;
	float u = distance_inverse;
	float du = distance_inverse / tan(alpha);
	float d2u;
    vec3 final_direction;
		
    for (int i = 0; i < MAX_ITER; i++)
    {
        d2u = 1.5*bh_radius*u*u - u;
		du += d2u * DELTA;
        u += du * DELTA;
        phi += DELTA; 

        final_direction = normalize(RotateByAxis(camera_origin, axis_rotation, phi)) / u;

        // Ray escapes to infinity
        if (u < INVERSE_SKY_DISTANCE)
        {
		    vec2 sphere_uv = sphereUV(final_direction);
		    px_color = gridTexture(sphere_uv, vec2(92.0, 92.0*0.5), white, pink);
            break;
        }
        // Ray falls to disk
		if (abs(final_direction.z) < 0.5 && u < inverse_inner_radius && u > inverse_outer_radius)
		{
            if ((abs(u-inverse_inner_radius) < 0.0001 || abs(u-inverse_outer_radius)<0.0001) && (abs(final_direction.z-0.5) < 0.1 || abs(final_direction.z+0.5) < 0.1))
                px_color = vec4(0.9,0.2,0.1,1);
            else
            {
                vec2 disk_uv = diskUV(final_direction, 60.0, 15.0);
                px_color = gridTexture(disk_uv, vec2(4,26), vec4(1,0.8,0,1), vec4(1,0.4,0.1,1));
            }
			break;
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