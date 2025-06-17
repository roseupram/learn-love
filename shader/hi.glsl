uniform float Time=0.0;
uniform mat4 projection;
uniform mat4 transform;
uniform mat4 view;

float freq=10.0;
float A=10;
float f=40;
float screen_size=200;

varying vec4 v_color;

#ifdef VERTEX
attribute vec3 origin;
vec4 position(mat4 transform_project, vec4 vertex_position){

    mat4 proj=mat4(
        2/screen_size*f,0,0,0,
        0,2/screen_size*f,0,0,
        0,0,2/screen_size,0,
        0,0,0,1
    );
    mat4 model=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        origin.x,origin.y,origin.z,1
    );
    vec4 pos=model*vertex_position;
    // pos.x += 4*A*sin(Time);
    //pos.z += A*cos(Time);
    pos.x/=pos.z;
    pos.y/=pos.z ;
    pos = proj*pos;
    v_color.z=(pos.x+1)/2;
    return pos;
}
#endif
#ifdef PIXEL


vec4 effect(vec4 color, Image texture,vec2 texture_coords,vec2 screen_coords){
    vec4 pixel= Texel(texture,texture_coords);
    //pixel.r=color.z;
    pixel.r=v_color.z;
    pixel.b=1-v_color.z;
    return pixel;
}
#endif