// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Expand 16-235 to 0-255";
   string Category    = "User";
   string SubCategory = "Broadcast";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

bool superwhite
<
	string Description = "Keep super whites";
> = false;

bool superblack
<
	string Description = "Keep super blacks";
> = false;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------

float4 NullPS(float2 xy : TEXCOORD1) : COLOR
{
    float highc = 20.0f / 255.0f;
    float lowc = 16.0f / 255.0f;
    float scale = 255.0f / 219.0f;

    float4 color = tex2D(FgSampler, xy.xy);
    float4 newcolor = (color-lowc) * scale;

    if (superwhite && !superblack) {
    	scale = 255.0f / 239.0f;
    	newcolor = (color - lowc) * scale;
    }

    if (!superwhite && superblack) {
    	scale = scale = 255.0f / 235.0f;
    	newcolor = ((color - highc) * scale) + highc;
    }

    if (superwhite && superblack) newcolor = color;

    if (newcolor.r > 1.0f) newcolor.r = 1.0f;
    if (newcolor.g > 1.0f) newcolor.g = 1.0f;
    if (newcolor.b > 1.0f) newcolor.b = 1.0f;
    if (newcolor.a > 1.0f) newcolor.a = 1.0f;
    if (newcolor.r < 0.0f) newcolor.r = 0.0f;
    if (newcolor.g < 0.0f) newcolor.g = 0.0f;
    if (newcolor.b < 0.0f) newcolor.b = 0.0f;
    if (newcolor.a < 0.0f) newcolor.a = 0.0f;

	return newcolor;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE NullPS();
   }
}

