function sketchbode(sys,overlayb)
%SKETCHBODE This function shows simple straight-line bode approximations
%
% HISTORY
% Feb. 2007 - Developed by Jeff DeCew at Olin College 
% Nov. 2015 - Updated by Brian Bingham for NPS distribution

if nargin < 2
    overlayb = 1;
end

    [MagW, MagM] = magtrace(sys);

    [PhsW, PhsP] = phasetrace(sys);
    
    if overlayb
        [mm,pp,ww] = bode(sys);
        subplot(211)
        semilogx(ww,20*log10(squeeze(mm)),'b','linewidth',2);
        hold on
        subplot(212)
        semilogx(ww,squeeze(pp),'b','linewidth',2);
        hold on
    end

    %figaxes = get(gcf, 'Children');

    %axes(figaxes(3));
    subplot(211)
    semilogx(MagW, MagM, 'ro-');
    ylabel('Mag. [dB]')
    title('Sketch Bode')
    grid on
    
    %axes(figaxes(1));
    subplot(212)
    semilogx(PhsW, PhsP, 'ro-');
    ylabel('Phase [deg]')
    xlabel('Frequency [rad/s]')
    %axis auto
    axis tight
    grid on
end


function [freq, phase] = phasetrace(sys)
    [Poles Zeros] = pzmap(sys);
    
    %[LeftVal RightVal CenterFreq Width]
    %[Phase_0 Phase_F  W_n        Zeta ]
    PZdata = [];
    for i = 1:length(Poles)
        w = abs(Poles(i));
        warning off all;
        decade = log10(w);
        warning on all;
        if abs( abs(Poles(i)) - abs(real(Poles(i))) ) < 1e-4 % is real
            z = 1;
        else
            z = real(-Poles(i))./w;
        end
        PZdata = [PZdata; 0, 90, decade, z];
    end
    
    for i = 1:length(Zeros)
        w = abs(Zeros(i));
        warning off all;
        decade = log10(w);
        warning on all;
        if abs( abs(Zeros(i)) - abs(real(Zeros(i))) ) < 1e-4 % is real
            z = 1;
        else
            z = real(-Zeros(i))./w;
        end
        PZdata = [PZdata; 0, -90, decade, z];
    end
    clear i w z Poles Zeros;
    
    x = [];
    for r=1:(size(PZdata))(1);
        c = PZdata(r,3);
        l = PZdata(r,3) - PZdata(r,4);
        r = PZdata(r,3) + PZdata(r,4);
        x = union(x,[l c r]);
    end
    x = fixfpe(x);
    x = union(x, x);
    if (isinf(x(1)))
        x = x(2:end);
    end
    [BodeM, BodeP, BodeW] = bode(sys);
    x = [log10(BodeW(1)); x(:); log10(BodeW(end))];

    for i = 1:length(x)
        p(i) = 0;
        for r = 1:(size(PZdata))(1);
            val = 0;
            if (x(i) <= (PZdata(r,3) - PZdata(r,4)))
                val = PZdata(r,1);
            elseif (x(i) >= (PZdata(r,3) + PZdata(r,4)))
                val = PZdata(r,2);
            else
                dw = 2* PZdata(r,4);
                dp = PZdata(r,2);
                val = (x(i) - PZdata(r,3)) * dp/dw + PZdata(r,2) / 2;
            end
            ps(i,r) = - val;
            p(i) = p(i) - val;
        end
    end
    
    %figure(2)
    %semilogx(10.^x,ps);
    
    phase = p;
    freq = 10.^x;
end

function [freq, mag] = magtrace(sys)
    [P Z] = pzmap(sys);
    
    P = abs(-P);
    Z = abs(-Z);

    P = fixfpe(P);
    Z = fixfpe(Z);
    
    [Np Vp] = bin(P);
    [Nz Vz] = bin(Z);
    clear P Z;
    
    Np = -Np;
    [N freq] = binmerge(Np, Vp, Nz, Vz); % Get binning where N is #zeros - #poles
    clear Np Vp Nz Vz;

    slope = 20*N; % 20 dB/decade per #Zeros - #Poles
    clear N;
    
    [BodeM, BodeP, BodeW] = bode(sys);

    M = 20*log10(BodeM(1)); % use bode min mag as start magnitude
    
    freq = [freq(:); BodeW(end)]; % use bode max omega as endpoint
        
    if (freq(1) == 0)
        freq(1) = BodeW(1); % use bode min omega as start, instead of zero
    else
        freq = [BodeW(1); freq(:)]; % start at bode min omega
        slope = [0 slope]; % start with zero slope
    end
    
    slope = cumsum(slope); % Of course, the slope is really the sum of all slopes a lower freqiencies
    decade = log10(freq); % Turn the frequency into decade power
    
    for i = 2:length(freq)
        dW = decade(i) - decade(i-1);
        M = [M M(end)+slope(i-1)*dW];
    end
    clear decade slope dW i;
    mag = M;
end

function [N V] = binmerge( N1, V1, N2, V2 )
    N=[];
    V=union(V1, V2);
    for v = V(:)';
        n=0;
        I1 = find(V1 == v);
        I2 = find(V2 == v);
        if (I1 > 0)
            n = N1(I1);
        end
        if (I2 > 0);
            n = n + N2(I2);
        end
        N=[N n];
    end
end

function [N V] = bin (list)
    list = sort(list);
    N = [];
    V = [];
    while 1
        if length(list)==0
            break;
        end
        v = list(1);
        n = length(find(list == v));
        V = [V v];
        N = [N n];
        list = list(n+1:end);
    end
end

function list = fixfpe(list)
    list = sort(list);
    for i=2:length(list)
        if abs( list(i) - list(i-1) ) < 1e-4
            list(i) = list(i-1);
        end
    end
end