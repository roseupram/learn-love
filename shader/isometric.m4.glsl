#pragma language glsl3
uniform float time=0;
uniform mat3 camera_param; 

/*
(
x,y,z,
x_rot,y_rot,radius
near,far,wh_ration
)
*/
include(`lib/tf.glsl')

vec4 position(mat4 _tf,vec4 vertex_position){
    return isometric_project(camera_param,vertex_position);
}