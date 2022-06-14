#include "Common.hlsl"

//Shadow
struct ShadowHitInfo
{
    bool isHit;
};

RaytracingAccelerationStructure SceneBVH : register(t2);

struct STriVertex {
    float3 vertex;
    float4 color;
};

cbuffer Colors : register(b0)
{
    float3 A;
    float3 B;
    float3 C;
}

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices: register(t1);

[shader("closesthit")] void ClosestHit(inout HitInfo payload,
    Attributes attrib) {
 
    float3 barycentrics = float3(1.f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);
    uint vertId = 3 * PrimitiveIndex();
    //float3 hitColor = float3(0.6, 0.7, 0.6);

    float3 hitColor = BTriVertex[indices[vertId + 0]].color * barycentrics.x + BTriVertex[indices[vertId + 1]].color * barycentrics.y + BTriVertex[indices[vertId + 2]].color * barycentrics.z;

    /*
    // Shade only the first 3 instances (triangles) 
    if (InstanceID() < 3) {
        hitColor = BTriVertex[indices[vertId + 0]].color * barycentrics.x + BTriVertex[indices[vertId + 1]].color * barycentrics.y + BTriVertex[indices[vertId + 2]].color * barycentrics.z;
    }
    */
    payload.colorAndDistance = float4(hitColor, RayTCurrent());

    /*
    float3 barycentrics = float3(1.f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);

    uint vertId = 3 * PrimitiveIndex();
    //float3 hitColor = BTriVertex[vertId + 0].color * barycentrics.x + BTriVertex[vertId + 1].color * barycentrics.y + BTriVertex[vertId + 2].color * barycentrics.z;
    

    //float3 hitColor = float3(0.7, 0.7, 0.7);
    float3 hitColor = A * barycentrics.x + B * barycentrics.y + C * barycentrics.z;
    */
    /*
    if (InstanceID() < 3)
    {
        hitColor = A[InstanceID()] * barycentrics.x + B[InstanceID()] * barycentrics.y + C[InstanceID()] * barycentrics.z;
    }
    */
    /*
    switch (InstanceID())
    {
    case 0:
        hitColor = BTriVertex[vertId + 0].color * barycentrics.x + BTriVertex[vertId + 1].color * barycentrics.y + BTriVertex[vertId + 2].color * barycentrics.z;
        break;
    case 1:
        hitColor = BTriVertex[vertId + 1].color * barycentrics.x + BTriVertex[vertId + 1].color * barycentrics.y + BTriVertex[vertId + 2].color * barycentrics.z;
        break;
    case 2:
        hitColor = BTriVertex[vertId + 2].color * barycentrics.x + BTriVertex[vertId + 1].color * barycentrics.y + BTriVertex[vertId + 2].color * barycentrics.z;
        break;
    }

    */
    
    //payload.colorAndDistance = float4(hitColor, RayTCurrent());
    
}

//Plane Shader
[shader("closesthit")]
void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
{
    /*
    float3 barycentrics = float3(1.f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);
    float3 hitColor = float3(0.7, 0.7, 0.3);
    payload.colorAndDistance = float4(hitColor, RayTCurrent());
    */

    //Shadow via Plane
    float3 lightPos = float3(2, 2, -2);
    
    float3 worldOrigin = WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
    float3 lightDir = normalize(lightPos - worldOrigin);
  
    RayDesc ray;
    ray.Origin = worldOrigin;
    ray.Direction = lightDir;
    ray.TMin = 0.01;
    ray.TMax = 100000;
    bool hit = true;
    // Initialize the ray payload 
    ShadowHitInfo shadowPayload;
    shadowPayload.isHit = false;
    // Trace the ray 
    TraceRay(SceneBVH, RAY_FLAG_NONE, 0xFF, 1, 0, 1, ray, shadowPayload);

    float factor = shadowPayload.isHit ? 0.3 : 1.0;
    float3 barycentrics = float3(1.f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);
    float4 hitColor = float4(float3(0.7, 0.7, 0.3) * factor, RayTCurrent());
    payload.colorAndDistance = float4(hitColor);
}
