function [ stsc, ddata ] = ts_stsc( data, type, param )
%TS_STSC Summary of this function goes here
%   Detailed explanation goes here
    
    switch type
        case 1 || 2
            n = length(data);
            nw = floor(n/param);
            dataw = data(1:nw*param);
            datawr = (reshape(dataw, param, nw))';
            if type == 1
                ms = median(datawr);
            else
                ms = mean(datawr);
            end
            ms = ms' - mean(ms);
            stsc = repmat(ms, nw, 1);
            stsc = [stsc; stsc(1:n-nw*param)];
        otherwise
            error('STSC estimation method not recognized');
    end
    
    ddata = data - stsc;
end
