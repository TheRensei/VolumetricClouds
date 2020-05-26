# VolumetricClouds
Volumetric clouds shader for Unity. 

(This project is in Unity 2019.1.8f1)

*I started learning shaders a month before uploading this so this shader is by no means perfect. Code is mostly commented, but everything *should* be clear enough.*

Features:

- Color of the clouds is modified by:
   - The Material itself
   - Lighting tab (Environment Lighting Gradient)
   - Light Color and Intensity
 - Subsurface scattering 
   - Is modified in the Material by "SSS power" and "SSS Strength"
 - Taper power is the strength of the cloud cut out depending on the distance from the center of the stack.
 - Modifiable clouds/sky curvature.
 - Clouds scroll with time.
 - Thickness and smoothness can be modified by:
   - CutOff
   - Cutout
   - Cloud Softness
 - *No Shadows*

![VC1](https://github.com/TheRensei/VolumetricClouds/blob/master/ScreenShots/VC1.gif)

![VC3](https://github.com/TheRensei/VolumetricClouds/blob/master/ScreenShots/VC3.gif)

![VC2](https://github.com/TheRensei/VolumetricClouds/blob/master/ScreenShots/VC2.gif)

![VC4](https://github.com/TheRensei/VolumetricClouds/blob/master/ScreenShots/VC4.gif)

![ ](https://github.com/TheRensei/VolumetricClouds/blob/master/ScreenShots/Capture.PNG)


References:

- Tutorial on Vol Clouds:

https://www.youtube.com/watch?v=LLUUIAKFgWg

- Modified quadStack script from this project:

https://www.patreon.com/posts/21646034

- Lighting:

https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html

- Curvature/Bend function:

https://www.bruteforce-games.com/post/curved-water-sea-shader-devblog-11
