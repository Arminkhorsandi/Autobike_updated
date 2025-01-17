function [Xref,Yref,Psiref] = ReferenceGenerator(type,ref_dis,N,scale)
%
%[Xref,Yref,Psiref] = ReferenceGenerator(type,ref_dis,N,scale)
%
% SHAPE : sharp_turn, line, infinite, circle, ascent_sin, smooth_curve,
% roset
% ref_dis  Distance between points ( 0.3-0.5 typically ok)
% N = 200   Number of reference points,, that is length is given by N*ref_dis
%
% Scale (only for infinite and circle - radius used
%
% For the option roset
%
% ReferenceGenerator(type,ref_dis,straightL,laps)
%
% straightL:  length of straig part, shorter gives tighter curve
% laps:   number of laps


    t = (0:(N-1))';
    switch type          
        case 'line'
            Xref = t*ref_dis;
            Yref = 0*ones(N,1);
 %           psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 

        case 'sharp_turn'
            t = t*ref_dis;
            Xref = 7*t;
            Yref = 5*[0*(1:300) 0.01*(1:800) 8*ones(1,1000)];
%            psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
            
        case 'smooth_curve'
            t = t*ref_dis;
            Xref = (300-t).*sin(0.15*t);
            Yref= -(300-t).*cos(0.15*t)+300;
 %           psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
            
        case 'circle'
            t = t*ref_dis/scale;
            Xref = scale*sin(t);
            Yref= -scale*cos(t)+30;
  %          psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
            
        case 'infinite'
            t = t*ref_dis/scale;;
            Xref = scale*cos(t);
            Yref = scale*sin(2*t) / 2;
   %         psiref =atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
            
        case 'ascent_sin'
            t = t*ref_dis;
            Xref = t*ref_dis;
            Yref = 8*sin(0.02*t+0.0004*t.*t);
  %          psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
        case 'wiggle'
            Amp = 10;
            fre = 0.01;
            Xref = t*ref_dis;
            Yref = Amp*sin(fre*t);
  %          psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1));
        case 'test'
            t = t*ref_dis;
            dis = 1;
            y= 1;
            Xref = dis*[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]';
            Yref = [0 0 0 0 0 0 0 0 0.333*y 0.666*y y y y y y y y y y y]';
   %         psiref=atan2(yref(2:N)-yref(1:N-1),xref(2:N)-xref(1:N-1)); 
        case 'roset'
            %
            % Distance between points
            %ref_dis = 0.3;
            laps=scale; %number of laps
            %ll=20; % Length of straight segment
            ll=N;
            
            % Number of reference points
            N=round(ll/2/ref_dis);
            [XrefL,YrefL] = ReferenceGenerator('line',ref_dis,N,scale);
            Xref=XrefL;
            Yref=YrefL;
            
            % rotated version -90 degrees
            rot=[0 1;-1 0];
            ref2=rot*[Xref Yref]';
            Xref2=ref2(1,:)';
            Yref2=ref2(2,:)'+ll/2;
            
            %segment to fit together the references
            [Xref3,Yref3]=circleSegment([Xref(end-1:end) Yref(end-1:end)],[Xref2(1:2) Yref2(1:2)],ref_dis);
            
            [Xref,Yref]=concatenate(Xref(1:end-1),Yref(1:end-1),Xref3,Yref3);
            %[Xref,Yref]=concatenate(Xref,Yref,Xref2,Yref2);
            Xrefq=[Xref;Xref2]; % keep half eight to be used later
            Yrefq=[Yref;Yref2];
            Xref=Xrefq;
            Yref=Yrefq;
            
            % make full eight by rotate
            [Xreftemp]=[Xref;-Yref];
            [Yref]=[Yref;-Xref];
            Xref=Xreftemp;
            % make full rosett by mirrow in y-axis            
            [Xref]=[Xref;Xref];
            [Yref]=[Yref;-Yref];

            % after the eight, add a quarter to change directions
            Zref1=[Xref Yref;
                Xrefq -Yrefq]';
            Zref=Zref1;
         
            % number of full cycles, rotate 90 degres and add
            for kk=1:laps
              Zref=[Zref [0 -1;1 0]^kk*Zref1];
            end
            Zref=Zref';
            [Xref]=Zref(:,1);
            [Yref]=Zref(:,2);


    end
    
   Psiref=atan2(Yref(2:end)-Yref(1:end-1),Xref(2:end)-Xref(1:end-1));

    % Xref=xref';%change row into column
    % Yref=yref';%change row into column
    % Psiref=psiref';%change row into column

    %start in origine
    Xref=Xref-Xref(1);
    Yref=Yref-Yref(1);
    Psiref = [Psiref(1); Psiref];
    % %Duplicate first value for first iteration in simulink (For proper delay value)
    % Xref = [Xref(1); Xref];
    % Yref = [Yref(1); Yref];
    % Psiref = [Psiref(1); Psiref(1); Psiref];
end

function [Xref,Yref]=circleSegment(Zref,Zref2,ref_dis)
% circle segment given two points corresponding to the two last points at
% start Zref and two first at the continuation Zref2 which becomes the end
% of the segmen
% 
    
    v1=Zref(2,:)-Zref(1,:);
    v2=Zref2(2,:)-Zref2(1,:);
    angle=acos(v1*v2'/(norm(v1)*norm(v2)))*sign(v1*[0 -1;1 0]*v2');
    if v1*(Zref2(1,:)-Zref(2,:))'<0
        angle=angle+pi*sign(angle);
    end
    radius=norm(Zref2(1,:)-Zref(2,:))/(2*sin(angle/2));
    N=round(abs(angle*radius/ref_dis)); % number of points
    % circle segmen
    [Xref,Yref] = ReferenceGenerator('circle',ref_dis,N,radius);
end

function [Xref,Yref]=concatenate(Xref,Yref,Xref2,Yref2)

    % put the second part after the first one in the correct direction
    
    % position in the origine
    Xref2=Xref2-Xref2(1);
    Yref2=Yref2-Yref2(1);
    
    % rotate
    v1=[Xref(end)-Xref(end-1) Yref(end)-Yref(end-1)];
    v2=[Xref2(2)-Xref2(1) Yref2(2)-Yref2(1)];
    v1=v1/norm(v1);
    v2=v2/norm(v2);
    th=acos(v1*v2')*sign(v1*[0 -1;1 0]*v2');
    rot=[cos(th) -sin(th);sin(th) cos(th)];
    ref2=rot*[Xref2 Yref2]';
    Xref2=ref2(1,:)';
    Yref2=ref2(2,:)';
    
    % position after last part
    Xref2=Xref2+2*Xref(end)-Xref(end-1);
    Yref2=Yref2+2*Yref(end)-Yref(end-1);
    % 
    % Xref=[Xref;Xref2(2:end)];
    % Yref=[Yref;Yref2(2:end)];    
    Xref=[Xref;Xref2];
    Yref=[Yref;Yref2];

end