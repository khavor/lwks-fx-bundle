//bilateral based on:
//Antitorgo's avishader 0.42 filter
//http://www.blosser.org/d9/dlAviShader042.rar

//--------------------------------------------------------------//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//
// Partial rewrite to address a Linux/Mac compatibility issue
// by Lightworks user jwrl 18 July 2017.
//
// In the process some code optimisation has been performed to
// improve execution times and lighten the GPU load.  Range
// values that result in divide by zero errors have been
// limited to safe values, and the "FrameSize" parameter is
// now labelled more appropriately "Blur window".
//
// The direction of operation of that control has also been
// reversed so that increasing values result in an increase
// of the blur window, and no longer a reduction.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "bilateral blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler2D InpSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MipFilter = Linear;
   MagFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.2;

float FrameSize
<
   string Description = "Blur window";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 fold_bilateral (float2 uv : TEXCOORD1) : COLOR
{
   float3 tempC0 = tex2D (InpSampler, uv).rgb;
   float3 Colour = tempC0;
   float3 normalizer = 1.0.xxx;
   float3 tempC1, tempC2, tempW;

   float2 position;

   float width  = _OutputWidth * max (0.002, 1.0 - max (0.0, FrameSize));
   float height = width / _OutputAspectRatio;

   float stepX = 1.0 / width;
   float stepY = 1.0 / height;

   float p = 1.0 / max (0.000001, 2.0 * Amount * Amount);

   float x = stepX;
   float y, optX, optY, tempG;

   for (int i = 0; i < 2; i++) {
      y = stepY;
      optX = x * x * width * width * 0.125;
      position = float2 (uv.x, uv.y + y);

      tempC1 = tex2D (InpSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv.x, uv.y - y);

      tempC1 = tex2D (InpSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv.x + x, uv.y);

      tempC1 = tex2D (InpSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = float2 (uv.x - x, uv.y);

      tempC1 = tex2D (InpSampler, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      for (int j = 0; j < 2; j++) {
         optX += y * y * height * height * 0.125;

         position = float2 (uv.x + x, uv.y + y);

         tempC1 = tex2D (InpSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv.x - x, uv.y + y);

         tempC1 = tex2D (InpSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv.x + x, uv.y - y);

         tempC1 = tex2D (InpSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = float2 (uv.x - x, uv.y - y);

         tempC1 = tex2D (InpSampler, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         y += stepY;
      }

      x += stepX;
   }

   return float4 (Colour / normalizer, 1.0);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique BilateralFilter
{
   pass Single_Pass { PixelShader = compile PROFILE fold_bilateral (); }
}