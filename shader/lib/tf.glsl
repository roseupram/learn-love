attribute vec3 a_tl;
attribute vec4 a_quat;
attribute vec3 a_sc;

mat4 quat_to_mat(vec4 quat){
    float x=quat.x,y=quat.y,z=quat.z,w=quat.w;
    float xx=x*x,xy=x*y,xz=x*z,xw=x*w;
    float yy=y*y,yz=y*z,yw=y*w;
    float zz=z*z,zw=z*w;
    return mat4(
        1-2*(yy+zz), 2*(xy-zw), 2*(xz+yw),0,
        2*(xy+zw), 1-2*(xx+zz),2*(yz-xw),0,
        2*(xz-yw),2*(yz+xw),1-2*(xx+yy),0,
        0,0,0,1
    );
}

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

mat4 translate_mat(vec3 tl){
    return mat4(
        1,0,0,0,
        0,1,0,0,
        0,0,1,0,
        tl,1);
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
vec4 world_pos(vec4 v){
    mat4 self_sc = scale_mat(length(a_sc)!=0?a_sc:vec3(1,1,1));
    mat4 self_rot=quat_to_mat(a_quat);
    mat4 model = self_sc*self_rot;
    v=model*v; // model
    v+=vec4(a_tl,0);
    return v;
}
/*
camera_param
(
x,y,z,
x_rot,y_rot,radius
near,far,wh_ration
)
*/
vec4 isometric_project(mat3 camera_param, vec4 vertex_position){
    float near=camera_param[2].x;
    float far=camera_param[2].y;
    float wh_ratio=camera_param[2].z;
    // TODO camera view 
    mat4 base_tl=translate_mat(camera_param[0]);
    float radius = camera_param[1][2];
    float sc = abs(1.0 /radius);
    mat4 scalate =scale_mat(sc,sc,sc);
    float x_rot=-camera_param[1].x;
    float y_rot=camera_param[1].y;
    mat4 rotate =rotate_mat(0,y_rot,0)*rotate_mat(x_rot,0,0);
    mat4 tf2world = base_tl*rotate;
    mat4 tf2cam = inverse(tf2world);
    float tsc = fract(time)+.5;
    tsc = 1;
    vertex_position=world_pos(vertex_position);

    // vec4 pos =rotate*scalate*vertex_position;
    vec4 pos =scalate*(vertex_position); //view
    pos=tf2cam*pos;
    pos.z*=-1; //right hand to left hand and scale back
    pos.z=(pos.z/sc-near)/(far-near);
    pos.y*=wh_ratio;
    return pos;
}