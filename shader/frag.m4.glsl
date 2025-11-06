#pragma language glsl3
uniform float time;
uniform vec3 light_position=vec3(1,1,1)*10;
uniform vec3 view_pos;
uniform vec3 light_color=vec3(1,1.0,1.0);
uniform float ambient=.2;
uniform float shiny=0.01;

varying vec4 v_color;
varying vec3 v_normal;
varying vec3 v_position; // world pos
vec4 effect(vec4 base_color, Image tex, vec2 tex_coord,vec2 screen_coord){
    vec4 tex_color= Texel(tex,tex_coord);
    vec4 color_tone=v_color;
    vec4 pixel=tex_color*base_color*color_tone; // scale it by 10, pure color
    pixel.r+=fract(time)*.001;
    if (pixel.a<.001) {
        discard;
    }
    if(length(v_normal)>0) {
        vec3 light_dir=normalize(light_position - v_position);
        float diff = max(dot(v_normal, light_dir), 0.0);
        vec3 diffuse = diff*light_color*tex_color.rgb;

        vec3 view_dir=normalize(view_pos-v_position);
        vec3 half_dir=normalize(light_dir+view_dir);
        float spec=pow(max(dot(v_normal,half_dir),0),2);
        vec3 specular=shiny*spec*light_color;
        pixel.rgb=pixel.rgb*ambient+ diffuse+specular;
    }
    return pixel;
}