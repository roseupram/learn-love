#pragma language glsl3
uniform float Time=0.0;
uniform float y_r;
uniform vec3 u_translate;
uniform float scale;
uniform float focal_len=100;
uniform float wh_ratio=1;
const float near = 30;
const float PI = asin(1.0)*2.0;

float freq=10.0;
float A=0;
float screen_size=200; //screen width

varying vec4 v_color;
varying float v_visible;

#ifdef VERTEX
attribute vec3 origin;
vec4 position(mat4 transform_project, vec4 vertex_position){

    mat4 proj=mat4(
        2/screen_size*focal_len,0,0,0,
        0,2/screen_size*focal_len*wh_ratio,0,0,
        0,0,.5/focal_len,0,
        0,0,0,1
    );
    mat4 scalate=mat4(
        scale,0,0,0,
        0,scale,0,0,
        0,0,scale,0,
        0,0,0,1
    );
    mat4 tranlate=mat4(
       1 ,0,0,0,
        0,1,0,0,
        0,0,1,0,
        origin.x,origin.y,origin.z,1
    );
    float x_rot=0;
    float y_rot=Time*0.+PI;
    //in rotate matrix, column is rotated axis
    mat4 rotate = mat4(
        cos(y_rot),0,sin(y_rot),0,
        0,cos(x_rot),-sin(x_rot),0,
        -sin(y_rot),sin(x_rot),cos(y_rot)*cos(x_rot),0,
        0,0,0,1
    );
    vec4 pos_world=tranlate*rotate*scalate*vertex_position; // world coord

    mat4 camera_t=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        u_translate,1
    );

    float cam_y_r=y_r;
    float cam_x_r=-.6+0.3*sin(Time);
    cam_x_r=0;
    mat4 camera_rot = mat4(
        cos(cam_y_r),   0,              sin(cam_y_r),0,
        0,              cos(cam_x_r),   -sin(cam_x_r),0,
        -sin(cam_y_r),  sin(cam_x_r),   cos(cam_x_r)*cos(cam_y_r),0,
        0,              0,              0,1
    );
    vec4 pos= inverse(camera_rot)*inverse(camera_t)*pos_world;
    float cos_angle_to_cam=pos.z/length(pos.xy);
    pos.x/=pos.z;
    pos.y/=pos.z;
    float cos_FOV=focal_len/length(vec2(focal_len,screen_size));
    if (cos_angle_to_cam<cos_FOV) {
        pos=vec4(0,0,-2,0);
        return pos;
    } 
    pos = proj*pos;
    float v = pos.y;
    v_color.z=v;
    return pos;
}
#endif
#ifdef PIXEL


vec4 effect(vec4 color, Image texture_,vec2 texture_coords,vec2 screen_coords){
    vec4 pixel= Texel(texture_,texture_coords);
    // pixel.r=VaryingColor.r;
    pixel*=VaryingColor;
    // float v = v_color.z;
    //  pixel.r= v;
    // pixel.b=1-v_color.z;
    return pixel;
}
#endif