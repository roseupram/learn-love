#pragma language glsl3
uniform float time=0.1;
uniform float wh_ratio=1;

uniform mat2x3 camera_param; //(x,y,z,x_rot,y_rot,radius)
uniform vec3 tl;

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

varying float z_value;
#ifdef VERTEX
vec4 position(mat4 transform_project, vec4 vertex_position){
    // TODO camera view 
    mat4 base_tl=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        camera_param[0],1);
    float radius = camera_param[1][2];
    float sc = abs(0.1 /radius);
    mat4 scalate = mat4(
        sc,0,0,0,
        0,sc,0,0,
        0,0,sc,0,
        0,0,0,1
    );
    float x_rot=-camera_param[1][0];
    float y_rot=camera_param[1][1];
    float sx=sin(x_rot),cx=cos(x_rot),sy=sin(y_rot),cy=cos(y_rot);
    mat4 eye_tl=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        radius*cx*sy, radius*sx,radius*cx*cy,1);
    mat4 rotate =rotate_mat(0,y_rot,0)*rotate_mat(x_rot,0,0);
    mat4 tf2world = base_tl*rotate;
    mat4 tf2cam = inverse(tf2world);
    // vec4 pos =rotate*scalate*vertex_position;
    vec4 pos =scalate*(vertex_position+vec4(tl,0));
    pos=tf2cam*pos;
    // z_value=camera_param[0].z;
    pos.z*=-1; //right hand to left hand
    pos.y*=wh_ratio;
    return pos;
}

#endif
#ifdef PIXEL
vec4 effect(vec4 base_color, Image tex,vec2 tex_coord, vec2 screen_coord){
    vec4 c=Texel(tex,tex_coord);
    // c.rgb*=fract(z_value);
    return base_color*c;
}
#endif