package;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.utils.Assets;
import flixel.FlxG;
import openfl.Lib;

class StaticShaderLQ extends FlxShader
{
    @:glFragmentSource('
uniform bool hasTransform;
uniform bool hasColorTransform;
uniform float openfl_Alphav;
uniform vec4 openfl_ColorMultiplierv;
uniform vec4 openfl_ColorOffsetv;
uniform sampler2D bitmap;

uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
uniform vec3 iResolution;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform float iTime;
uniform bool enabled;
uniform sampler2D noiseTex;
uniform float alpha;

float simpleNoise(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
    vec4 color = texture2D(bitmap, coord, bias);
    
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

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    if (!enabled) {
        fragColor = flixel_texture2D(bitmap, uv, 0.0);
    } else {
        float yOffset = sin(iTime * 2.0) * 0.05;
        float xOffset = simpleNoise(vec2(iTime * 15.0, uv.y * 80.0)) * 0.003;

        float staticVal = simpleNoise(vec2(uv.x, uv.y + yOffset)) * 0.1;

        vec3 color = vec3(
            flixel_texture2D(bitmap, vec2(uv.x + xOffset - 0.01, uv.y + yOffset), 0.0).r,
            flixel_texture2D(bitmap, vec2(uv.x + xOffset, uv.y + yOffset), 0.0).g,
            flixel_texture2D(bitmap, vec2(uv.x + xOffset + 0.01, uv.y + yOffset), 0.0).b
        ) + staticVal;

        float scanline = sin(uv.y * 800.0) * 0.04;
        color -= scanline;

        vec4 baseColor = flixel_texture2D(bitmap, uv, 0.0);
        fragColor = mix(vec4(color, 1.0), baseColor, alpha) * baseColor.a;
    }
}

void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}

    ')
    public function new()
        {
          super();
        }
}