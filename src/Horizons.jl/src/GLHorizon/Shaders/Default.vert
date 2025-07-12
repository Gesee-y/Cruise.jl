// Default vertex shader //

void main()
{
	gl_Position = vec4(VERTEX.x,-VERTEX.y,VERTEX.z,1.0);
}