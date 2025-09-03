#pragma language glsl3
uniform float time=0.1;
uniform mat3 camera_param; 
/*
(
x,y,z,
x_rot,y_rot,radius
near,far,wh_ration
)
*/

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

mat4 rotate_mat(vec3 rot){
    return rotate_mat(rot.x,rot.y,rot.z);
}
mat4 scale_mat(float x,float y, float z){
    return mat4(
        x,0,0,0,  
        0,y,0,0,  
        0,0,z,0,  
        0,0,0,1  
    );
}
mat4 scale_mat(vec3 sc){
    return scale_mat(sc.x,sc.y,sc.z);
}

varying vec4 vp;
#ifdef VERTEX
attribute vec3 a_tl;
attribute vec3 a_rot;
attribute vec3 a_sc;
/*
x,y,z
x_rot,y_rot,z_rot,
x_sc,y_sc,c_sc
*/
vec4 position(mat4 transform_project, vec4 vertex_position){
    float near=camera_param[2].x;
    float far=camera_param[2].y;
    float wh_ratio=camera_param[2].z;
    // TODO camera view 
    mat4 base_tl=mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        camera_param[0],1);
    float radius = camera_param[1][2];
    float sc = abs(1.0 /radius);
    mat4 scalate = mat4(
        sc,0,0,0,
        0,sc,0,0,
        0,0,sc,0,
        0,0,0,1
    );
    float x_rot=-camera_param[1].x;
    float y_rot=camera_param[1].y;
    float sx=sin(x_rot),cx=cos(x_rot),sy=sin(y_rot),cy=cos(y_rot);
    // mat4 eye_tl=mat4(
    //     1,0,0,0,
    //     0,1,0,0,
    //     0,0,1,0,
    //     radius*cx*sy, radius*sx,radius*cx*cy,1);
    mat4 rotate =rotate_mat(0,y_rot,0)*rotate_mat(x_rot,0,0);
    mat4 tf2world = base_tl*rotate;
    mat4 tf2cam = inverse(tf2world);
    float tsc = fract(time)+.5;
    tsc = 1;
    vp=vertex_position;
    mat4 self_sc = scale_mat(length(a_sc)!=0?a_sc:vec3(1,1,1));
    vertex_position=self_sc*rotate_mat(a_rot)*vertex_position;
    vertex_position+=vec4(a_tl,0);
    // vec4 pos =rotate*scalate*vertex_position;
    vec4 pos =scalate*(vertex_position);
    pos=tf2cam*pos;
    pos.z*=-1; //right hand to left hand and scale back
    pos.z=(pos.z/sc-near)/(far-near);
    // z_value=pos.z;
    pos.y*=wh_ratio;
    return pos;
}

#endif
#ifdef PIXEL
vec4 effect(vec4 base_color, Image tex_,vec2 tex_coord, vec2 screen_coord){
    vec4 c=Texel(tex_,tex_coord);
    c*=base_color;
    if(length(vp.xyz)>sqrt(3)){
        c *= .5+.5*sin(time);
    }
    // c.rgb*=z_value;
    return c;
}
#endif