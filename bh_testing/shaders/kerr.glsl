#version 430 core
precision highp float;  

// Constants
const float PI        = 3.1415926535897932384626433832795;
const float TWO_PI    = 6.283185307179586476925286766559;  
const float INV_TWO_PI= 0.15915494309189533576888376337251;
const float PI_2      = 1.5707963267948966192313216916398; 

// Scene settings
const float DELTA = -0.05;
const int MAX_ITER = 3000000;
const float VERT_PRECISION = 0.009;

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
uniform float a;

// Constants
float M = 0.5 * bh_radius;
float BH_HORIZON = M + sqrt(M*M - a*a) + 1e-1;
float SKY_DISTANCE = 50.0;

// External textures
layout(binding = 1) uniform sampler2D background_texture;

// Functions
mat4 KerrMetric(vec4 bl_coords)
{
    float r = bl_coords.y;
    float theta = bl_coords.z;
    float phi = bl_coords.w;

    // Compute sin and cos beforehand
    float sin_theta = sin(theta);
    float sin2_theta = sin_theta * sin_theta;
    float cos2_theta = 1.0 - sin2_theta;

    // Helper variables
    float Sigma = r*r + a*a * cos2_theta;
    float Delta = r*r - 2.0*M*r + a*a;
    
    // Compute metric components
    mat4 g = mat4(0.0);
    g[0][0] = -(1.0 - (2.0*M*r) / Sigma);
    g[1][1] = Sigma / Delta;
    g[2][2] = Sigma;
    g[3][3] = sin2_theta * (r*r + a*a + (2.0*M*r*a*a*sin2_theta / Sigma));
    
    float g_tphi = -2.0*M*r*a*sin2_theta / Sigma;
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

    return (-B - sqrt(B*B - 4.0*A*C)) / (2.0*A);
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

    float sin_theta = sin(bl_coords.z);

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

float aspect_ratio = resolution.x / resolution.y;
vec3 ShootRay(vec2 uv)
{
    uv = 2.0*uv - 1.0;
    uv.y /= aspect_ratio;

    vec3 ray_direction = normalize(vec3(focal_length, uv));
    
    return rotation_matrix * ray_direction;
}


vec4 KerrDerivative(vec4 y, vec3 constants, out float dphi)
{
    float E  = constants.x;
    float Lz = constants.y;
    float C  = constants.z;    

    float r      = y.x;
    float dr     = y.y;
    float theta  = y.z;
    float dtheta = y.w;

    float sin_theta = sin(theta);
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
    float d2theta = (Theta_prime_halves - Sigma*dSigma * dtheta) / (Sigma*Sigma);

    dphi = ((1.0 - 2.0*M*r / Sigma) * Lz/(sin2_theta) + 2.0*M*r*a*E / Sigma) / Delta;

    return vec4(dr, d2r, dtheta, d2theta);
}



void main()
{
    ivec2 pixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = vec2(pixelCoord) / resolution;

    vec3 cartesian_velocity = -ShootRay(uv);
    
    // Convert to Boyer-Lindquist coordinates
    vec4 bl_coords, bl_velocity;
    Cartesian2BoyerLindquist(camera_origin, cartesian_velocity, bl_coords, bl_velocity);

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

    // Begin backwards ray-tracing
    vec4 px_color = vec4(0,1,1,1);
    vec4 y = vec4(r, dr, theta, dtheta);
    for (int i = 0; i < MAX_ITER; i++)
    {
        float k1_phi, k2_phi, k3_phi, k4_phi;
        vec4 k1 = DELTA * KerrDerivative(y,            constants, k1_phi);
        vec4 k2 = DELTA * KerrDerivative(y + 0.5 * k1, constants, k2_phi);
        vec4 k3 = DELTA * KerrDerivative(y + 0.5 * k2, constants, k3_phi);
        vec4 k4 = DELTA * KerrDerivative(y + k3,       constants, k4_phi);
       
        y   += (k1 + 2.0*(k2 + k3) + k4) / 6.0;

        float dphi = (k1_phi + 2.0*(k2_phi + k3_phi) + k4_phi) / 6.0;
        phi += DELTA * dphi;

        float r      = y.x;
        float dr     = y.y;
        float theta  = y.z;
        float dtheta = y.w;

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
            px_color = texture(background_texture, vec2(-sphere_uv.x, sphere_uv.y));
            break;
        }
    }
    imageStore(img_output, pixelCoord, px_color);
}