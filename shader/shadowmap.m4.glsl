#pragma language glsl3
uniform float time=0;
uniform mat3 camera_param; 
uniform mat4 light_view;

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
attribute vec3 a_normal;
varying vec4 v_color;
varying vec3 v_normal;
varying vec3 v_position;

vec4 position(mat4 _tf,vec4 vertex_position){
    v_color=a_color;
    v_normal=a_normal;
    v_position=vertex_position.xyz;
    vertex_position=world_pos(vertex_position);
    return light_view*vertex_position;
}
#endif
//end of vertex code