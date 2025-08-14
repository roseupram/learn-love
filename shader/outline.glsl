uniform float lw = .1;
const float Threshod=.5;

bool on_edge(Image tex, vec2 uv, float width) {
    bool res = false;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 dir1 = vec2(width * i, width * j);
            res = res || Texel(tex, uv + dir1).a >= Threshod;
        }
    }
    return res;
}

vec4 effect(vec4 base_color, Image tex, vec2 uv, vec2 screen_coords) {
    vec4 edge_color = vec4(.9, .6, .1, 1);
    vec4 texcolor = Texel(tex, uv);
    if (lw > 0 && texcolor.a < Threshod && on_edge(tex, uv, lw)) {
        texcolor = edge_color;
    }
    return texcolor * base_color;
}