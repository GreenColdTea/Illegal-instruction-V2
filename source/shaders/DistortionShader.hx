package shaders;

import shaders.flixel.FlxShader;

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
    #pragma header
    uniform float iTime;

    vec2 getDistortion(vec2 uv, float d, float t) {
	uv.x += cos(d) + t * 0.9;
	uv.y += sin(d + t * 0.75);
	return uv;
    }

    vec4 getDistortedTexture(sampler2D iChannel, vec2 uv) {
    	vec4 rgb = texture(iChannel, uv);
    	return rgb;
    }
    
    void main()
    {
    	vec2 uv = fragCoord.xy / iResolution.xy;
    	float t = iTime;
    	vec2 mid = vec2(0.5,0.5);
    	vec2 focus = iMouse.xy / iResolution.xy;
    	float d1 = distance(focus+sin(t * 0.25) * 0.5,uv);	
    	float d2 = distance(focus+cos(t),uv);	
    	vec4 rgb = (getDistortedTexture(iChannel0, getDistortion(uv, d1, t)) + getDistortedTexture(iChannel1, getDistortion(uv, -d2, t))) * 0.5;
    	rgb.r /= d2;
    	rgb.g += -0.5 + d1;
    	rgb.b = -0.5 + (d1 + d2) / 2.0;
    	gl_FragColor = rgb;
}')
public function new()
    {
		super();
	}
}