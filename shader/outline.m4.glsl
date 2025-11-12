include(`isometric.m4.glsl')

#ifdef PIXEL
//start of frag
uniform float lw = .01;
float Threshod=.5;
uniform vec4 edge_color = vec4(1,1,1,1);
varying vec4 v_color ;


bool on_edge(Image tex, vec2 uv, float width) {
    bool res = false;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 dir1 = vec2(width * i, width * j);
            res = res || Texel(tex, uv + dir1).a >= Threshod;
            if (res) return true;
        }
    }
    return res;
}

vec4 effect(vec4 base_color, Image tex, vec2 uv, vec2 screen_coords) {
    vec4 texcolor = Texel(tex, uv);
    vec4 color_tone= v_color;
    if (lw > 0 && texcolor.a < Threshod && on_edge(tex, uv, lw)) {
        texcolor = edge_color;
    }
    texcolor.r+=fract(time)*.001;
    gl_FragDepth = gl_FragCoord.z+float(texcolor.a<.001);
    return texcolor * base_color*color_tone;
}
#endif
//end of frag
