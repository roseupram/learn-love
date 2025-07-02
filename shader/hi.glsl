#pragma language glsl3
uniform float Time=0.0;
uniform float y_r=0.0;
uniform vec3 u_translate;
uniform float focal_len=100;
uniform float wh_ratio=1;
float near = 1;
float far= focal_len*4;
const float PI = asin(1.0)*2.0;

float freq=10.0;
float A=0;
float screen_size=200; //screen width

varying vec4 v_color;
varying float v_depth;
varying vec3 v_normal;

#ifdef VERTEX
attribute vec3 a_origin;
attribute vec3 a_scale;
attribute vec3 a_rotation;
attribute vec3 a_normal;
vec4 position(mat4 transform_project, vec4 vertex_position){

    mat4 scalate=mat4(
        a_scale.x,0,0,0,
        0,a_scale.y,0,0,
        0,0,a_scale.z,0,
        0,0,0,1
    );
    mat4 tranlate=mat4(
       1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        a_origin,1
    );
    float x_rot=0;
    float y_rot=0;
    //in rotate matrix, column is rotated axis
    mat4 rotate = mat4(
        cos(y_rot),0,sin(y_rot),0,
        0,cos(x_rot),-sin(x_rot),0,
        -sin(y_rot),sin(x_rot),cos(y_rot)*cos(x_rot),0,
        0,0,0,1
    );
    mat4 self_transform = tranlate*rotate*scalate;
    vec4 pos_world=self_transform*vertex_position; // world coord

    vec4 nor=rotate*scalate*vec4(a_normal,1);
    v_normal=normalize(nor.xyz);
    mat4 camera_t=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        u_translate,1
    );

    float cam_y_r=y_r;
    float cam_x_r=0;
    mat4 camera_rot = mat4(
        cos(cam_y_r),   0,              sin(cam_y_r),0,
        0,              cos(cam_x_r),   -sin(cam_x_r),0,
        -sin(cam_y_r),  sin(cam_x_r),   cos(cam_x_r)*cos(cam_y_r),0,
        0,              0,              0,1
    );
    vec4 pos= inverse(camera_t*camera_rot)*pos_world; // pos in camera coordinate
    // float cos_angle_to_cam=pos.z/length(pos.xyz);
    float dist=abs(pos.z);
    pos.x/=dist;
    pos.y/=dist;
    // float cos_FOV=focal_len/length(vec2(focal_len,screen_size/2));

    mat4 proj=mat4(
        2/screen_size*focal_len,0,0,0,
        0,2/screen_size*focal_len*wh_ratio,0,0,
        0,0,1,0,
        0,0,-near,1
    );
    pos = proj*pos;
    float z=pos.z;
    z=z/(far-near)*2-1;
    pos.z=z;
    float v = pos.z;
    v_depth=v;
    return pos;
}
#endif
#ifdef PIXEL


vec4 effect(vec4 color, Image texture_,vec2 texture_coords,vec2 screen_coords){
    vec4 pixel= Texel(texture_,texture_coords);
    // pixel.r=VaryingColor.r;
    pixel*=VaryingColor;
    vec3 light = 1.5*normalize(vec3(sin(Time),1,cos(Time)));
    pixel.rgb=pixel.rgb*dot(v_normal,light);
    // float dist =(1+v_depth)/2; 
    // pixel.a=1-dist*dist;
    // pixel.b=1-v_color.z;
    return pixel;
}
#endif