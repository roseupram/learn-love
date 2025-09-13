#pragma language glsl3
uniform float time;
uniform mat3 camera_param; 
varying vec4 v_color;
vec4 effect(vec4 base_color, Image tex, vec2 tex_coord,vec2 screen_coord){
    vec4 tex_color= Texel(tex,tex_coord);
    // vec4 color_tone=length(v_color.rgb)==0? vec4(1,1,1,1):v_color;
    vec4 color_tone=v_color;
    vec4 pixel=tex_color*base_color*color_tone; // scale it by 10, pure color
    pixel.r+=fract(time)*.001;
    gl_FragDepth = gl_FragCoord.z+float(pixel.a<.001);
    return pixel;
}