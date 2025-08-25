#pragma language glsl3
uniform float time=0.1;
uniform float wh_ratio=1;

float x_rotate=radians(30+10*sin(time));
float y_rotate=radians(-45);

mat4 rotate_mat(float x,float y,float z){
    /*
    x 
    1,0, 0,
    0,cx,-sx,
    0,sx,cx,

    y
    cy, 0,sy,
    0,  1,0,
    -sy,0,cy,

    z
    cz,-sz,0,
    sz,cz, 0
    0, 0,  1
    */
    float sx=sin(x),sy=sin(y),sz=sin(z);
    float cx=cos(x),cy=cos(y),cz=cos(z);
    /*
    xy_rotate=mat4(
        cy,  sx*sy, sy*cx,0,
        0,   cx,    -sx,0,
        -sy, sx*cy, cx*cy,0,
        0,0,0,1
    );
    */
    mat4 rotate=mat4(
        cy*cz+sz*sx*sy, -sz*cy+cz*sx*sy, sy*cx, 0,
        sz*cx,          cz*cx,           -sx,   0,
        -sy*cz+sz*sx*cy, sz*sy+cz*sx*cy, cx*cy, 0,
        0,0,0,1
    );
    return rotate;
}

vec4 position(mat4 transform_project, vec4 vertex_position){
    // TODO camera view 
    vec3 tl=vec3(-.1*cos(2*time),-.3*sin(time),0);
    // TODO wired rotation
    float sc = 1.0 / 6;
    mat4 scalate = mat4(
        sc,0,0,0,
        0,sc,0,0,
        0,0,-sc,0,
        0,0,0,1
    );
    mat4 rotate =rotate_mat(x_rotate,y_rotate,0);
    vec4 pos =rotate*scalate*vertex_position;
    pos.y*=wh_ratio;
    return pos;
}

vec4 effect(vec4 base_color, Image tex,vec2 tex_coord, vec2 screen_coord){
    vec4 c=Texel(tex,tex_coord);
    return base_color*c;
}