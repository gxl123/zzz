uniform sampler2D samplerY; // Y texture sampler
uniform sampler2D samplerU; // U texture sampler
uniform sampler2D samplerV; // V texture sampler

varying mediump vec2 TexCoordOut;

const mediump mat3 yuv2rgb = mat3(1, 1, 1,
                          0, -0.39465, 2.03211,
                          1.13983, -0.58060, 0);

void main(void)
{
    mediump vec3 yuv;
    yuv.x = texture2D(samplerY, TexCoordOut).r;
    yuv.y = texture2D(samplerU, TexCoordOut).r - 0.5;
    yuv.z = texture2D(samplerV, TexCoordOut).r - 0.5;
    
    lowp vec3 rgb = yuv2rgb * yuv;
    
    gl_FragColor = vec4(rgb, 1.0);
}