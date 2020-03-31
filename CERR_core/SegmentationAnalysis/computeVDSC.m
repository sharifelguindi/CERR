function [DCE] = computeVDSC(n,m)

    Seg1 = m(:);
    Seg2 = n(:);
    VoxelsNumber1=sum(Seg1); 
    VoxelsNumber2=sum(Seg2);
    CommonArea=sum(Seg1 & Seg2); 
    DCE =(2*CommonArea)/(VoxelsNumber1+VoxelsNumber2);
    if DCE > 0.995
        DCE = 1;
    end
end

