#pragma language glsl3
uniform float time;
uniform mat3 camera_param; 
vec4 effect(vec4 base_color, Image tex, vec2 tex_coord,vec2 screen_coord){
    vec4 tex_color= Texel(tex,tex_coord);
    vec4 pixel=tex_color*base_color;
    pixel.r+=fract(time)*.001;
    return pixel;
}