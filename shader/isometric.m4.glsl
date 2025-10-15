#pragma language glsl3
uniform float time=0;

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


vec4 position(mat4 _tf,vec4 vertex_position){
    return isometric_project(vertex_position);
}
#endif
//end of vertex code