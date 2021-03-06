// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Added subcategory for version 14, 18 Feb 2017 - jwrl.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Regional zoom";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




float Zoom
<
	string Description = "zoom";
	float MinVal = -1.00;
	float MaxVal = 1.00;
> = 0.00;



float Area
<
	string Description = "Area";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.95;



float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;


bool Flip_edge
<
	string Description = "Flip edge";
> = true;



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler FgSamplerBorder = sampler_state
{
   Texture = <Input>;
   AddressU = Border;
   AddressV = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


///////////////////////////////////////////////
// Definitions  and declarations             //
///////////////////////////////////////////////

float _OutputAspectRatio;
	
#define AREA  (200-Area*201)




//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//--------------------------------------------------------------


float4 zoom (float2 xy : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - xy; 				// XY Distance between the current position to the adjusted effect centering
 float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio)); 	// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 										// Macro, Pick up the rendered variable ( "strengthCycle" (-1 to +1) , 16-bit color by using two 8-bit colors)
 float zoom = Zoom;
 float distortion = (distance * ((distance * AREA) + 1.0) + 1);			// Creates the distortion
 if (Area != 1) zoom = zoom / max( distortion, 0.1 ); 				// If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero 

 if (!Flip_edge) return tex2D (FgSamplerBorder, zoom * xydist + xy);
 return tex2D (FgSampler, zoom * xydist + xy); 

} 



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE zoom();
   }
}

