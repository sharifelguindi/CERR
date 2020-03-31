function [sliceDCE] = computeSliceDSC(n, m, volume_m)

    % n - auto contour
    % m - final contour
    
    arr_size = size(n);
    sliceDCE = zeros(3, arr_size(3));
    
    for i = 1:arr_size(3)
        Seg1 = m(:,:,i);
        Seg2 = n(:,:,i);
        
        if (max(Seg1(:)) == 1)
            sliceDCE(3, i) = 1;
        else
            sliceDCE(3, i) = 0;
        end
        
                
        if (max(Seg2(:)) == 1)
            sliceDCE(2, i) = 1;
        else
            sliceDCE(2, i) = 0;
        end
        
        if (max(Seg1(:)) == 1) || (max(Seg2(:)) == 1)
            VoxelsNumber1=sum(Seg1(:)); 
            VoxelsNumber2=sum(Seg2(:));
            CommonArea=sum(Seg1(:) & Seg2(:)); 
            sliceDCE(1, i) =(2*CommonArea)/(VoxelsNumber1+VoxelsNumber2);
            
            if volume_m > 10000
                if sliceDCE(1, i) >= 0.99
                    sliceDCE(1, i) = 1;
                end
            else
                if sliceDCE(1, i) >= 0.95
                    sliceDCE(1, i) = 1;
                end
            end
            
        else
            sliceDCE(1, i) = -1;
        end 
    end
end

