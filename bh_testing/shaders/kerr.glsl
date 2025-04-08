#version 430 core

// Constants
const float PI = 3.14159265358979323846;

// Scene settings
const float DELTA = 0.1;
const int MAX_ITER = 10000000;

// Output texture
layout(local_size_x = 32, local_size_y = 32) in;
layout(binding = 0, rgba32f) uniform image2D img_output;

uniform vec2 resolution;

// Constants
float a = 0.5;
float M = 1.0;
float BH_HORIZON = M * (1.0 + sqrt(1.0 - (a*a)/(M*M)));
float SKY_DISTANCE = 30.0;

// External textures
layout(binding = 1) uniform sampler2D background_texture;

// Functions
vec3 BoyerLindquist2Cartesian(vec3 bl_coords)
{
    float r = bl_coords.x;
    float theta = bl_coords.y;
    float phi = bl_coords.z;

    float x = sqrt(r*r + a*a) * sin(theta) * cos(phi);
    float y = sqrt(r*r + a*a) * sin(theta) * sin(phi);
    float z = r * cos(theta);

    return vec3(x, y, z);
}

vec3 CartesianDirection(vec3 bl_coords, vec3 d_bl)
{
    float r = bl_coords.x;
    float theta = bl_coords.y;
    float phi = bl_coords.z;

    float dr = d_bl.x;
    float dtheta = d_bl.y;
    float dphi = d_bl.z;

    float dx = -sqrt(a*a + r*r)*sin(phi)*sin(theta)*dphi + sqrt(a*a + r*r)*cos(phi)*cos(theta)*dtheta + r*sin(theta)*cos(phi)*dr/sqrt(a*a + r*r);
    float dy =  sqrt(a*a + r*r)*sin(phi)*cos(theta)*dtheta + sqrt(a*a + r*r)*sin(theta)*cos(phi)*dphi + r*sin(phi)*sin(theta)*dr/sqrt(a*a + r*r);
    float dz = -r*sin(theta)*dtheta + cos(theta)*dr;

    return normalize(vec3(dx, dy, dz));
}

vec3 ComputeConstants(vec3 initial_conditions, vec2 angles)
{
    float r = initial_conditions.x;
    float theta = initial_conditions.y;
    float phi = initial_conditions.z;

    float alpha = angles.x;
    float beta = angles.y;

    float sin_theta2 = sin(theta)*sin(theta);
    float cos_theta2 = 1.0 - sin_theta2;

    // Compute metric components
    float rho2 = r*r + a*a * cos_theta2;
    float delta = r*r - 2.0*M*r + a*a;
    
    float g_tt = -(1.0 - (2.0*M*r) / rho2);
    float g_tphi = -2.0*M*a*r*sin_theta2 / rho2;
    float g_rr = rho2 / delta;
    float g_thetatheta = rho2;
    float g_phiphi = sin_theta2 * (r*r + a*a + (2.0*M*r*a*a*sin_theta2 / rho2));

    // Compute gamma and zeta
    float factor = sqrt(g_phiphi / (g_tphi * g_tphi - g_tt * g_phiphi));
    float gamma = -g_tphi / g_phiphi * factor;
    float zeta = factor;

    // Compute the actual constants
    float p_theta = sqrt(g_thetatheta) * sin(alpha);
    float p_phi =  sqrt(g_phiphi) * sin(beta) * cos(alpha);

    float Phi = p_phi;
    float E = ((1.0 + gamma * sqrt(g_phiphi) * sin(beta) * cos(alpha)) / zeta);
    float Q = p_theta*p_theta + cos_theta2 * (a*a * (-E*E) + (p_phi*p_phi / sin_theta2)); 

    return vec3(E, Phi, Q);
}

vec2 SphereUV(vec3 direction)
{
    direction = normalize(direction);
    float u = 0.5 + atan(direction.y, direction.x)/(2.0*PI);
    float v = 0.5 + asin(direction.z)/PI;

    return vec2(u, v);
}

void main()
{
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(pixelCoord) / resolution;

    vec4 px_color = vec4(0,0,0,1);

    vec2 angles = 2.0*uv - 1.0;
    angles = PI/4.0 * angles;
    vec3 initial_conditions = vec3(25.0, PI/2.0, 0.0);
    
    float r = initial_conditions.x;
    float theta = initial_conditions.y;
    float phi = initial_conditions.z;

    // Compute constants
    vec3 constants = ComputeConstants(initial_conditions, angles);

    float E = constants.x;
    float Phi = constants.y;
    float Q = constants.z;

    // Begin ray-tracing
    while (true) //for (int i = 0; i < MAX_ITER; i++)
    {
        // Precompute sin and cos
        float sin_theta2 = sin(theta)*sin(theta);
        float cos_theta2 = 1.0 - sin_theta2;
        
        // The equations
        float rho2 = r*r + a*a * cos_theta2;
        float Delta = r*r - 2.0*M*r + a*a;

        float H = E * (r*r + a*a) - a * Phi;

        float R = H*H - Delta * (Q + (a*E - Phi)*(a*E - Phi));
        float Theta = Q - cos_theta2 * (a*a * (-E*E) + (Phi / sin_theta2));

        float dr = sqrt(abs(R)) / rho2;
        float dtheta = sqrt(abs(Theta)) / rho2;
        float dphi = (2.0*M*a*E*r/Delta + Phi*((Delta - a*a * sin_theta2) / (Delta * sin_theta2))) / rho2;

        // Update variables
        r -= dr * DELTA;
        theta -= dtheta * DELTA;
        phi -= dphi * DELTA;

        // Check terminating conditions
        if (r < BH_HORIZON)
        {
            px_color = vec4(0,1,0,1);
            break;
        }
        if (r > SKY_DISTANCE)
        {
            vec3 final_direction = CartesianDirection(vec3(r, theta, phi), vec3(dr, dtheta, dphi));
            vec2 sphere_uv = SphereUV(final_direction);
            px_color = texture(background_texture, sphere_uv);
            break;
        }
    }
    imageStore(img_output, pixelCoord, px_color);
}