// file:///C:/Users/pedro/Desktop/tfg/references/2008.04384v2%20(1).pdf

#version 430 core

// Constants
const float PI = 3.14159265358979323846;

// Scene settings
const float DELTA = 0.008;
const int MAX_ITER = 100000;
const float VERT_PRECISION = 0.001;

// Output texture
layout(local_size_x = 32, local_size_y = 32) in;
layout(binding = 0, rgba32f) uniform image2D img_output;

uniform vec2 resolution;
uniform float a;

// Constants
float M = 1.0;
float BH_HORIZON = M + sqrt(M*M - a*a);
float SKY_DISTANCE = 45.0;
float focal_length = 1.5;

// External textures
layout(binding = 1) uniform sampler2D background_texture;

// Functions
mat4 KerrMetric(vec4 bl_coords)
{
    float r = bl_coords.y;
    float theta = bl_coords.z;
    float phi = bl_coords.w;

    // Compute sin and cos beforehand
    float sin_theta = max(sin(theta), VERT_PRECISION);
    float sin2_theta = sin_theta * sin_theta;
    float cos2_theta = 1.0 - sin2_theta;

    // Helper variables
    float Sigma = r*r + a*a * cos2_theta;
    float Delta = r*r - 2.0*M*r + a*a;
    
    // Compute metric components
    mat4 g = mat4(0.0);
    g[0][0] = 1.0 - (2.0*M*r) / Sigma;
    g[1][1] = -Sigma / Delta;
    g[2][2] = -Sigma;
    g[3][3] = -sin2_theta * (r*r + a*a + (2.0*M*r*a*a*sin2_theta / Sigma));
    
    float g_tphi = 2.0*M*r*a*sin2_theta / Sigma;
    g[0][3] = g_tphi;
    g[3][0] = g_tphi;
    
    return g;
}


float ComputeFirstComponentVelocity(float t, float r, float theta, float phi, float dr, float dtheta, float dphi)
{
    mat4 g = KerrMetric(vec4(t, r, theta, phi));

    float A = g[0][0];
    float B = 2.0*g[0][3] * dphi;
    float C = dot(vec3(g[1][1], g[2][2], g[3][3]), vec3(dr*dr, dtheta*dtheta, dphi*dphi));

    return (-B + sqrt(B*B - 4.0*A*C)) / (2.0*A);
}

void Cartesian2BoyerLindquist(vec3 cartesian_coords, vec3 cartesian_velocity, out vec4 bl_coords, out vec4 bl_velocity)
{
    float x = cartesian_coords.x;
    float y = cartesian_coords.y;
    float z = cartesian_coords.z;

    float dx = cartesian_velocity.x;
    float dy = cartesian_velocity.y;
    float dz = cartesian_velocity.z;

    float w     = dot(cartesian_coords, cartesian_coords) - a*a;
    float t     = 0.0;
    float r     = sqrt(0.5 * (w + sqrt(w*w + 4.0*a*a*z*z)));
    float theta = acos(z / r);
    float phi   = atan(y, x);

    float dw     = 2.0 * dot(cartesian_coords, cartesian_velocity); 
    float dr     = (0.25 / r) * (dw + (w*dw + 4.0*a*a*z*dz) / (2.0*r*r - w));
    float dtheta = - (dz*r - z*dr) / (r*r * (sqrt( 1.0 - ((z*z) / (r*r)) )));
    float dphi   = (dy*x - y*dx) / (x*x * ( 1.0 + ((y*y) / (x*x)) ));

    float dt = ComputeFirstComponentVelocity(t, r, theta, phi, dr, dtheta, dphi);

    bl_coords = vec4(t, r, theta, phi);
    bl_velocity = vec4(dt, dr, dtheta, dphi);
}

vec3 BoyerLindquist2Cartesian(vec4 bl_coords)
{
    float r     = bl_coords.y;
    float theta = bl_coords.z;
    float phi   = bl_coords.w;

    float radius_sin_theta = sqrt(r*r + a*a) * sin(theta);

    float x = radius_sin_theta * cos(phi);
    float y = radius_sin_theta * sin(phi);
    float z = r * cos(theta);

    return vec3(x, y, z);
}

vec3 BoyerLindquist2CartesianDirection(vec4 bl_coords, vec4 bl_velocity)
{
    float r     = bl_coords.y;
    float theta = bl_coords.z;
    float phi   = bl_coords.w;

    float dr     = bl_velocity.y;
    float dtheta = bl_velocity.z;
    float dphi   = bl_velocity.w; 

    float radius = sqrt(r*r + a*a);
    float dx = (r*dr / radius) * sin(theta) * cos(phi) + radius * (cos(theta)*cos(phi)*dtheta - sin(theta)*sin(phi)*dphi);
    float dy = (r*dr / radius) * sin(theta) * sin(phi) + radius * (cos(theta)*sin(phi)*dtheta + sin(theta)*cos(phi)*dphi);
    float dz = dr*cos(theta) - r*sin(theta)*dtheta;

    return vec3(dx, dy, dz);
}

vec3 ComputeConstants(vec4 bl_coords, vec4 bl_velocity)
{
    float dt     = bl_velocity.x; 
    float dr     = bl_velocity.y;
    float dtheta = bl_velocity.z;
    float dphi   = bl_velocity.w;

    float sin_theta = max(sin(bl_coords.z), VERT_PRECISION);

    // Compute metric
    mat4 g = KerrMetric(bl_coords);
    float g_tt         = g[0][0];
    float g_thetatheta = g[2][2];
    float g_phiphi     = g[3][3];
    float g_tphi       = g[0][3];

    //Compute actual constants
    float E = g_tt * dt + g_tphi * dphi;
    float Lz = -(g_phiphi * dphi + g_tphi * dt);

    float pi_theta = g_thetatheta * dtheta;
    float C = pi_theta*pi_theta + (a*E*sin_theta - Lz/sin_theta)*(a*E*sin_theta - Lz/sin_theta);

    return vec3(E, Lz, C);
}

vec2 SphereUV(vec3 direction)
{
    direction = normalize(direction);
    float u = 0.5 + atan(direction.y, direction.x)/(2.0*PI);
    float v = 0.5 + asin(direction.z)/PI;

    return vec2(u, v);
}

// Camara:
//             2.0 
// +-------------------------+
// |                         |
// |            +            |  2.0 / aspect_ratio
// |            |            |
// +------------|------------+
//  \           |           /
//   \          | focal    /
//    \         | length  /   
//     \        |        /
//      .       |       .
//       ·      :      ·

float aspect_ratio = resolution.x / resolution.y;
vec3 ShootRay(vec2 uv)
{
    uv = 2.0*uv - 1.0;
    uv.y /= aspect_ratio;

    vec3 ray_direction = normalize(vec3(-focal_length, uv));
    
    return ray_direction;
}

void main()
{
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(pixelCoord) / resolution;

    vec3 cartesian_velocity = ShootRay(uv);
    
    vec3 cartesian_coords = vec3(-40, 0, 0);
    
    // Convert to Boyer-Lindquist coordinates
    vec4 bl_coords, bl_velocity;
    Cartesian2BoyerLindquist(cartesian_coords, cartesian_velocity, bl_coords, bl_velocity);

    float t      = bl_coords.x;
    float r      = bl_coords.y;
    float theta  = bl_coords.z;
    float phi    = bl_coords.w;

    float dt     = bl_velocity.x;
    float dr     = bl_velocity.y;
    float dtheta = bl_velocity.z;
    float dphi   = bl_velocity.w;
    
    // Compute constants
    vec3 constants = ComputeConstants(bl_coords, bl_velocity);
    float E = constants.x;
    float Lz = constants.y;
    float C = constants.z;

    // Begin backwards ray-tracing
    vec4 px_color = vec4(0,1,1,1);
    float R_sign = 1.0;
    float Theta_sign = dtheta > 0.0 ? 1.0 : -1.0;
    for (int i = 0; i < MAX_ITER; i++)
    {
        // Precompute sin and cos
        float sin_theta = max(sin(theta), VERT_PRECISION);
        float cos_theta = cos(theta);
        float sin2_theta = sin_theta * sin_theta;
        float cos2_theta = 1.0 - sin2_theta;
        
        float Sigma = r*r + a*a*cos2_theta;
        float Delta = r*r - 2.0*M*r + a*a;
        
        float R_prime_halves = 2.0*r*E * ((r*r + a*a)*E - a*Lz) - (r - M)*C;
        float Theta_prime_halves = -(a*E*sin_theta - Lz/sin_theta) * (a*E*cos_theta + Lz*cos_theta/sin2_theta);

        // Equations of motion
        float dSigma  = 2.0 * (r*dr - a*a*cos_theta*sin_theta*dtheta);
        float d2r     = (R_prime_halves - Sigma*dSigma * dr) / (Sigma*Sigma);
        //float d2r = (R_prime_halves - 2.0*r*Sigma*dr*dr + 2.0*Sigma*a*a*sin_theta*cos_theta*dtheta*dr) / (Sigma*Sigma);
        //float d2theta = (Theta_prime_halves + 2.0*a*a*Sigma*sin_theta*cos_theta*dtheta*dtheta - 2.0*r*Sigma*dr*dtheta) / (Sigma*Sigma);

        float d2theta = (Theta_prime_halves - Sigma*dSigma * dtheta) / (Sigma*Sigma);

        float dphi = ((1.0 - 2.0*M*r / Sigma) * Lz/(sin2_theta) + 2.0*M*r*a*E / Sigma) / Delta;
        
/*
        float R_prime_halves = 2.0 * E*r*dr*((r*r + a*a)*E - a*Lz) - (C + (a*E - Lz)*(a*E - Lz)) *dr*(r - M);
        float Theta_prime_halves = cos_theta*sin_theta*dtheta * (-a*a*E*E + Lz*Lz / sin2_theta) + Lz*Lz * cos_theta*cos2_theta / (sin_theta*sin2_theta);
        
        float dSigma  = 2.0 * (r*dr - a*a*cos_theta*sin_theta*dtheta);
        float d2r     = (R_prime_halves - Sigma*dSigma * dr*dr) / (Sigma*Sigma * dr);
        float d2theta = (Theta_prime_halves - Sigma*dSigma * dtheta*dtheta) / (Sigma*Sigma * dtheta);

        float dphi = (2.0*M*r*a*E / Sigma + Lz*(Delta - a*a * sin2_theta) / sin2_theta) / (Sigma*Delta);*/

        // Update the position and velocity (negative because we are going backwards)
        dr -= d2r * DELTA;
        r -= dr * DELTA;

        dtheta -= d2theta * DELTA;
        theta -= dtheta * DELTA;

        phi -= dphi * DELTA;

        // Check terminating conditions
        if (r <= BH_HORIZON)
        {
            px_color = vec4(0,0,0,1);
            break;
        }
        if (r > SKY_DISTANCE)
        {
            vec3 final_direction = BoyerLindquist2CartesianDirection(vec4(0, r, theta, phi), vec4(dt, dr, dtheta, dphi));
            vec2 sphere_uv = SphereUV(final_direction);
            px_color = texture(background_texture, sphere_uv);
            break;
        }
    }
    // vec2 sphere_uv = SphereUV(direction);
    // px_color = texture(background_texture, sphere_uv);
    imageStore(img_output, pixelCoord, px_color);
}