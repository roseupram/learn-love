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
#ifdef VERTEX
// include attribute
include(`lib/tf.glsl')

attribute vec4 a_color;
varying vec4 v_color;

vec4 position(mat4 _tf,vec4 vertex_position){
    v_color=a_color;
    return isometric_project(camera_param,vertex_position);
}
#endif
//end of vertex code