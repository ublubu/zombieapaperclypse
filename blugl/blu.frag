#version 410 core

uniform vec4 inputColor;

in vec4 fragColor;

out vec4 fColor;

void main()
{
   fColor = fragColor + inputColor;
}
