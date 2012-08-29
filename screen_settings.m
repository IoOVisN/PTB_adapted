function screen_settings
% function [Widths Heights Hzs] = screen_settings(spec_pixsize)

spec_pixsize=8;
Sn = max(Screen('Screens'));
Widths(Sn,166) = zeros;
Heights(Sn,166) = zeros;
Hzs(Sn,166) = zeros;

for  i = 1:Sn
    res = Screen(i, 'Resolutions');
    L = length(res);
    width(1:L) = zeros;
    height(1:L) = zeros;
    pixelSize(1:L) = zeros;
    hz(1:L) = zeros;

    for j = 1:length(res)
        width(j) = res(j).width;
        height(j)= res(j).height;
        pixelSize(j) = res(j).pixelSize;
        hz(j) = res(j).hz;
    end
    pS = (pixelSize == spec_pixsize);
    LpS = length(find(pS == 1));
    
    Widths(i,1:LpS) = width(pS);
    Heights(i,1:LpS) = height(pS);
    Hzs(i,1:LpS) = hz(pS);
    LLpS(i) = LpS;
%   PixelSize(i,LpS) = 0;        
%   PixelSize(i,:) = pixelSize(pS);  % no need to extract this, is there..?
    
end

LL = max(LLpS);
Widths = Widths(:,1:LL)
Heights = Heights(:,1:LL)
Hzs = Hzs(:,1:LL)
