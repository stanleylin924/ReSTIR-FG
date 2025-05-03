struct Reservoir{

    uint M;             // Number of samples. Real number equals generatedSamples * M
    float targetFunc; // Target Pdf of current sample
    float weightSum;    // Weight of the reservoir after finalizing (W in paper). Used as weightSum internaly
    float3 vPos;        // Position of the visible point
    float3 vNorm;       // Normal of the visible point
    uint age;           // Age of the sample
    uint2 pad;          // Pad for fitting
    
    //Empty init
    __init(){
        this = {};
        M = 0;
        weightSum = 0.f;
        vPos = float3(0);
        vNorm = float3(0);
        age = 0;
    }

    //Updates reservoir with new light sample. Returns true if the light sample was selected
    [mutating] bool updateReservoir(const float invSelectPdf,const float lstargetFunc, const float rnd){
        float risWeight = lstargetFunc * invSelectPdf;
        weightSum += risWeight;
        M += 1;
        bool selectSample = (rnd * weightSum < risWeight);
    
        if(selectSample){
            targetFunc = lstargetFunc;
        }
        return selectSample;
    }

    //Combines another reservoir with this reservoir. Returs true if the new reservoir was selected
    [mutating] bool combineReservoir(in const Reservoir other, const float othertargetFunc,const float rnd){
        float normalizationFactor = other.weightSum * other.M;

        float risWeight = othertargetFunc * normalizationFactor;
    
        M += other.M;
    
        weightSum += risWeight;

        bool selectSample = (rnd * weightSum < risWeight);
    
        if(selectSample){
            targetFunc = othertargetFunc;
        }

        return selectSample;
    }

    //Finalizes a sample. Normalizes the Wsum to W (and uses weightSum to store W)
    [mutating] void finalizeSample(float normalizationNumerator, float normalizationDenominator){
        float denominator = targetFunc * normalizationDenominator;
        
        if(denominator > 0)
            weightSum = (weightSum * normalizationNumerator) / denominator;
        else
            weightSum = 0;
    }
};
