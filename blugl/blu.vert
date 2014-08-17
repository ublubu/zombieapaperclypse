#version 410 core

layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;

out vec4 fragColor;

void
main()
{
   gl_Position = vPosition;
   fragColor = vColor;
}
