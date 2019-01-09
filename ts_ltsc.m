function [ ltsc, ddata ] = ts_ltsc( data, type, param, ext )
%TS_LTSC Summary of this function goes here
%   Detailed explanation goes here

    switch type
        case 'W'
            % Wavelet db24
            dwtmode('sp0','nodisp');
            dataext = [data; mean(data(end-ext+1:end))];
            [C, L] = wavedec(dataext, param + 2, 'db24');
            ltsc = wrcoef('a', C, L, 'db24', param);
            ltsc = ltsc(1:end-1,:);
        case 'HP'
            % HP filter
            ltsc = hpfilter(data, param);
        case 'EMD'
            % EMD filter
            [~, ltsc] = emd_processing(data, param);
        otherwise
            error('LTSC estimation method not recognized');
    end
    
    ddata = data - ltsc;
end
