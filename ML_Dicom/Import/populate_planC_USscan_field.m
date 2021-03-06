function dataS = populate_planC_USscan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES, type)
%"populate_planC_scan_field"
%   Given the name of a child field to planC{indexS.scan}, populates that
%   field based on the data contained in the dcmdir.PATIENT.STUDY.SERIES
%   structure passed in.  Type defines the type of series passed in.
%
%JRA 06/15/06
%
%YWU Modified 03/01/08
%NAV 07/19/16 updated to dcm4che3
%       replaced dcm2ml_Element with getTagValue
%
%Usage:
%   dataS = populate_planC_scan_field(fieldname, dcmdir_PATIENT_STUDY_SERIES);
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

%For easier handling.
SERIES = dcmdir_PATIENT_STUDY_SERIES;

%Default value for undefined fields.
dataS = '';

switch fieldname
    case 'scanArray'
        dataS   = uint16([]);
        zValues = [];

        %Determine number of images
        nImages = length(SERIES.Data);

        %Iterate over slices.
        for imageNum = 1:nImages

            IMAGE   = SERIES.Data(imageNum);

            attr  = scanfile_mldcm(IMAGE.file);

            try
                %Pixel Data
                sliceV = getTagValue(attr, '7FE00010');

                %Rows
                nRows  = getTagValue(attr, '00280010');

                %Columns
                nCols  = getTagValue(attr, '00280011');

                %Pixel Representation
                pixRep = getTagValue(attr, '00280103');
                
                %Bits Allocated
                bitsAllocated = getTagValue(attr, '00280100');
                
                switch pixRep
                    case 0
                        if bitsAllocated == 16 || bitsAllocated == 32
                            if strcmpi(class(sliceV),'int32')
                                if bitsAllocated == 16
                                    sliceV = typecast(sliceV,'uint16');
                                else
                                    sliceV = typecast(sliceV,'uint32');
                                end
                                sliceV = sliceV(1:2:end);
                            else
                                sliceV = typecast(sliceV,'uint16');                                
                            end
                        elseif bitsAllocated == 8
                            if strcmpi(class(sliceV),'int8')
                                if bitsAllocated == 8
                                    sliceV = typecast(sliceV,'uint8');
                                end
                            end
                            sliceV = sliceV(1:2:end);
                        end
                    case 1
                        if bitsAllocated == 16 || bitsAllocated == 32
                            if strcmpi(class(sliceV),'int32')
                                if bitsAllocated == 16
                                    sliceV = typecast(sliceV,'int16');
                                else
                                    sliceV = typecast(sliceV,'int32');
                                end
                                sliceV = sliceV(1:2:end);
                            else
                                sliceV = typecast(sliceV,'int16');
                            end
                        elseif bitsAllocated == 8
                            sliceV = typecast(sliceV,'uint8');
                        end
                    otherwise
                        sliceV = typecast(sliceV,'int16');
                        
                end

                if attr.contains(hex2dec('00280008'))
                    % Try to see if tag Number Of Frames is present
                    numofframe  = getTagValue(attr, '00280008');

                    if numofframe > 1 && imageNum == 1
                        errordlg('This is Multiframe Ultrasound Study !! We do not support this data type.');
                    end
                else

                    if attr.contains(hex2dec('00280002'))
                        % Samples Per Pixel (Check to see if it is a RGB image)
                        samples_Per_Pixel = getTagValue(attr, '00280002');
                    else
                        samples_Per_Pixel = 1;
                    end

                    %Shape the slice.
                    %slice2D = reshape(sliceV, [nRows nCols samples_Per_Pixel]);
                    for iRGB = 1:samples_Per_Pixel
                        slice2D(:,:,iRGB) = reshape(sliceV(iRGB:samples_Per_Pixel:end),...
                            [nCols nRows])';
                    end
                end
            catch
                slice2D = dicomread(IMAGE.file);
            end

            samples_Per_Pixel = getTagValue(attr, '00280002');
            if samples_Per_Pixel == 3
                try
                    slice2D = rgb2gray(slice2D);
                catch
                end
            end

            %Store zValue for sorting, converting DICOM mm to CERR cm and
            %inverting to match CERR's z direction.

            % This is a private tag done by Envisioneering Medical
            % Technologies to provide Z coordinates

            try %wy ImageTranslationVectorRET
                transV = getTagValue(attr, '00185212');
                %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
                zValues(imageNum)  = -transV(3)/10;
            catch
                disp('error: scan Z-value error!');
            end

            %Store the slice in the 3D matrix.
            dataS(:,:,imageNum) = slice2D;

            clear imageobj;

        end

        %Reorder 3D matrix based on zValues.
        if ~isempty(zValues)
            [jnk, zOrder]       = sort(zValues);
            dataS(:,:,1:end)    = dataS(:,:,zOrder);
        end

    case 'scanType'

    case 'scanInfo'
        %Determine number of images
        nImages = length(SERIES.Data);

        %Get scanInfo field names.
        scanInfoInitS = initializeScanInfo;
        names = fields(scanInfoInitS);

        zValues = [];

        %Iterate over slices.
        for imageNum = 1:nImages

            IMAGE   = SERIES.Data(imageNum);
            attr  = scanfile_mldcm(IMAGE.file);

            % This is a private tag done by Envisioneering Medical
            % Technologies to provide Z coordinates
            try %wy ImageTranslationVectorRET
                transV = getTagValue(attr, '00185212');
                %Convert from DICOM mm to CERR cm, invert Z to match CERR Zdir.
                zValues(imageNum)  = -transV(3)/10;
            catch
                if nImages == 1 % 2d ultrasound
                    zValues(imageNum) = 0;
                else
                    error('error: scan Z-value error!');
                end
            end

            for i = 1:length(names)
                dataS(imageNum).(names{i}) = populate_planC_USscan_scanInfo_field(names{i}, IMAGE, attr, imageNum);
            end

            clear imageobj;

        end

        %Reorder scanInfo elements based on zValues.
        [jnk, zOrder]   = sort(zValues);

        dataS(1:end)    = dataS(zOrder);

    case 'uniformScanInfo'
        %Implementation is unnecessary.
    case 'scanArraySuperior'
        %Implementation is unnecessary.
    case 'scanArrayInferior'
        %Implementation is unnecessary.
    case 'thumbnails'
        %Implementation is unnecessary.
    case 'transM'
        %Implementation is unnecessary.
    case 'scanUID'
        %Series Instance UID
        dataS = getTagValue(SERIES.info, '0020000E');
    otherwise
        %         warning(['DICOM Import has no methods defined for import into the planC{indexS.scan}.' fieldname ' field, leaving empty.']);
end