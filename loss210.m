function [ losses ] = loss210( e, a1, a2, g1, g2, r1, r2, m )
%LOSS210 L210 synthetic loss function of Cheng and Yang (2015)
%   
%   a1 - degree of concern about the forecast errors under the L2-loss, recommended values are 0.5 or 0.1
%   a2 - protection against outliers: the larger the higher penalty for outliers
%   g1 - the right bounds of L0, recommended value is 2
%   g2 - the left bounds of L0, recommended value is and -2
%   r1  - the sharp of right jumps (range from 0 to 1): the larger the sharper, recommended values from 0.5 to 0.9
%   r2  - the sharp of left jumps (range from 0 to 1): the larger the sharper, recommended values from 0.5 to 0.9
%   
%   Cheng, G. and Yang, Y., 2015. Forecast combination with outlier protection. International Journal of Forecasting 31,
%   223-237. http://dx.doi.org/10.1016/j.ijforecast.2014.06.004.

    if(nargin < 8)
        m = std(e);
    elseif(ischar(m))
        switch m
            case 'median'
                m = median(abs(e));
            case 'mean'
                m = mean(abs(e));
            case 'std'
                m = std(e);
            otherwise
                error(['Scaling factor type "', combType, '" is not recognized']);
        end
    end

    l2 = e.^2;
    l1= abs(e);
    l0 = (e>g1*m) + (e<g2*m) + ...
        (e>=(g1*m*r1)).*(e<=(g1*m)).*(1-(1./(g1*m).^2)*(1/(1-r1)^2).*(e-g1*m).^2) + ...
        (e>=(g2*m)).*(e<=(g2*m*r2)).*(1-(1./(g2*m).^2)*(1/(1-r2)^2).*(e-g2*m).^2);

    losses = l1 + a1*l2./m + a2*m.*l0;
end

