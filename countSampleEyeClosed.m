function retVec = countSampleEyeClosed( eyeOpen )
    eyeBlinkCount = 0;
    currentlyOpen = false;
    %retVec = zeros(2, length(eyeOpen) );
    for i = 1:length(eyeOpen)
        if (currentlyOpen)
            if (eyeOpen(i) == 0)
                currentlyOpen = false;
            end
        else
            if (eyeOpen(i) == 1)
                currentlyOpen = true;
                eyeBlinkCount = eyeBlinkCount + 1;
            end
        end
    end
    
    retVec = zeros(2, eyeBlinkCount);
    blinkIdx = 1;
    prevOpen = 0;
    
    for i = 1:length(eyeOpen)
        if (currentlyOpen)
            if (eyeOpen(i) == 0)
                currentlyOpen = false;
                retVec(1, blinkIdx) = prevOpen;
                retVec(2, blinkIdx) = i - 1;
                blinkIdx = blinkIdx + 1;
            end
        else
            if (eyeOpen(i) == 1)
                currentlyOpen = true;
                prevOpen = i;
            end
        end
    end
    
    disp(["Average segment sample size: " string(sum(eyeOpen)/eyeBlinkCount)]);
end