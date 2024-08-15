package;
import flixel.system.FlxAssets.FlxShader;

class BarrelDistortionShader extends FlxShader {
    @:isVar
    public var barrelDistortion1(get, set):Float = 0;
    @:isVar
    public var barrelDistortion2(get, set):Float = 0;

    // Getters and setters should match the property type
    function get_barrelDistortion1():Float
        return dis1.value[0];
    
    function set_barrelDistortion1(val:Float):Float {
        dis1.value[0] = val;
        return val; // Must return the set value
    }

    function get_barrelDistortion2():Float
        return dis2.value[0];
    
    function set_barrelDistortion2(val:Float):Float {
        dis2.value[0] = val;
        return val; // Must return the set value
    }

    @:glFragmentSource('
        #pragma header
        uniform float dis1;
        uniform float dis2;
        uniform sampler2D iChannel0;

        vec2 brownConradyDistortion(in vec2 uv, in float k1, in float k2)
        {
            uv = uv * 2.0 - 1.0;
            float r2 = uv.x * uv.x + uv.y * uv.y;
            uv *= 1.0 + k1 * r2 + k2 * r2 * r2;
            uv = (uv * 0.5 + 0.5);
            return uv;
        }

        void main()
        {
            vec2 uv = openfl_TextureCoordv;

            float k1 = dis1;
            float k2 = dis2;

            uv = brownConradyDistortion(uv, k1, k2);

            float scale = abs(k1) < 1.0 ? 1.0 - abs(k1) : 1.0 / (k1 + 1.0);
            uv = uv * scale - (scale * 0.5) + 0.5;

            vec3 c = texture(iChannel0, uv).rgb;

            vec2 uv2 = abs(uv * 2.0 - 1.0);
            vec2 border = 1.0 - smoothstep(vec2(0.95), vec2(1.0), uv2);
            c *= mix(0.2, 1.0, border.x * border.y);

            float vignetteRange = clamp(k1, 0.0, 0.2);
            float dist = distance(uv, vec2(0.5, 0.5));
            dist = (dist - (0.707 - vignetteRange)) / vignetteRange;
            float mult = smoothstep(1.0, 0.0, dist);
            c *= mult;

            gl_FragColor = vec4(c, texture(iChannel0, uv).a);
        }
    ')
    public function new() {
        super();
        dis1.value = [0.0];
        dis2.value = [0.0];
    }
}
