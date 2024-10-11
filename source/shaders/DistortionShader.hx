package shaders;
import flixel.system.FlxAssets.FlxShader;

class DistortionShader
{
    public var shader(default, null):DistortionShad = null;
    public function new()
    {
        shader = new DistortionShad();
        shader.iTime.value = [0];
    }
    public function update(elapsed:Float)
    {
        shader.iTime.value[0] += elapsed;
    }
}

class DistortionShad extends FlxShader {
    @glFragmentSource('
    // Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel
#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture texture2D

// Transformation parameters
uniform bool hasTransform; 
uniform bool hasColorTransform; 
uniform vec4 openfl_ColorMultiplierv;
uniform vec4 openfl_ColorOffsetv;
uniform float openfl_Alphav;

// Function to handle texture sampling
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
    vec4 color = texture(bitmap, coord);
    if (!hasTransform) {
        return color;
    }
    if (color.a == 0.0) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    if (!hasColorTransform) {
        return color * openfl_Alphav;
    }
    color = vec4(color.rgb / color.a, color.a);
    mat4 colorMultiplier = mat4(0);
    colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
    colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
    colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
    colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
    color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
    if (color.a > 0.0) {
        return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
    }
    return vec4(0.0, 0.0, 0.0, 0.0);
}

// Variables that might be empty
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;

vec2 brownConradyDistortion(vec2 uv) {
    float barrelDistortion1 = 0.15; // K1 in textbooks
    float barrelDistortion2 = 0.0; // K2 in textbooks
    float r2 = uv.x * uv.x + uv.y * uv.y;
    uv *= 1.0 + barrelDistortion1 * r2 + barrelDistortion2 * r2 * r2;
    return uv;
}

vec2 easyBarrelDistortion(vec2 uv) {
    float demoScale = 1.1;
    uv *= demoScale;
    float th = atan(uv.x, uv.y);
    float barrelDistortion = 1.2;
    float r = pow(sqrt(uv.x * uv.x + uv.y * uv.y), barrelDistortion);
    uv.x = r * sin(th);
    uv.y = r * cos(th);
    return uv;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.y = 1.0 - uv.y; // Flip the Y coordinate
    uv = uv * 2.0 - 1.0; // Normalize to [-1, 1]

    uv = brownConradyDistortion(uv); // Apply distortion

    uv = 0.5 * (uv * 0.5 + 1.0); // Remap to [0, 1]
    
    fragColor = flixel_texture2D(iChannel0, uv, 0.0); // Sample texture
}

void main() {
    mainImage(gl_FragColor, openfl_TextureCoordv * openfl_TextureSize); // Entry point for the shader
}')
public function new()
    {
		super();
	}
}
