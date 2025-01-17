
% 
% % Distance between points
% ref_dis = 0.3;
% % Scale (only for infinite and circle)
% scale=0;
% 
% test of git
%
% ll=30; % Length of straight segment
% % Number of reference points
% N=round(ll/ref_dis);
% [XrefL,YrefL] = ReferenceGenerator('line',ref_dis,N,scale);
% Xref=XrefL;
% Yref=YrefL;
% 
% % circle segment
% N=145;
% scale=9.995;  % Radius
% [Xref2,Yref2] = ReferenceGenerator('circle',ref_dis,N,scale);
% 
% [Xref,Yref]=concatenate(Xref,Yref,Xref2,Yref2);
% 
% % another  line
% [Xref,Yref]=concatenate(Xref,Yref,XrefL,YrefL);
% 
% % another curve in oposite direction
% [Xref,Yref]=concatenate(Xref,Yref,Xref2,-Yref2);
% 
% Here is a change to check GIT
%
% % addapt 'nl' last point to make it connect to the spltart point, and then a
% % periodical trajectory can be made by repeating
% 
% nl=4;
% Xref(end-nl+1:end)=Xref(end-nl)+(1:nl)'*(Xref(1)-Xref(end-nl))/(nl+1);
% Yref(end-nl+1:end)=Yref(end-nl)+(1:nl)'*(Yref(1)-Yref(end-nl))/(nl+1);
% 
% for nn=11:0,  % perform a number of eights.
%     Xref=[Xref;Xref];
%     Yref=[Yref;Yref];
% end
% 
% % v1=[Xref(end)-Xref(end-1);Yref(end)-Yref(end-1)];
% % v2=[Xref(2)-Xref(1);Yref(2)-Yref(1)];
% 
% 
% %[Xref,Yref]=circleSegment([0 0; 1 0],[10 10;10 11],ref_dis);
% 
% % repeat but rotate 90 degrees
% 
% % rotated version
% rot=[0 -1;1 0];
% ref2=rot*[Xref Yref]';
% Xref2=ref2(1,:)';
% Yref2=ref2(2,:)';
% % cut part of beginning
% dist=25;
% nl=round(dist/ref_dis);
% Xref2=Xref2(nl:end)+15;
% Yref2=Yref2(nl:end)-15;
% 
% % add a line to the end of the first part
% Xref=[Xref;XrefL(1:round(length(XrefL)/6))];
% Yref=[Yref;YrefL(1:round(length(XrefL)/6))];
% 
% %segment to fit together the references
% [Xref3,Yref3]=circleSegment([Xref(end-1:end) Yref(end-1:end)],[Xref2(1:2) Yref2(1:2)],ref_dis);
% 
% [Xref,Yref]=concatenate(Xref,Yref,Xref3,Yref3);
% [Xref,Yref]=concatenate(Xref,Yref,Xref2,Yref2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ref_dis = 0.3;
laps=4;
lL=30;
[Xref,Yref,Psiref] = ReferenceGenerator('roset',ref_dis,lL,laps);


plot(Xref,Yref,'o')

% hold off
% plot(Xref(end-100:end),Yref(end-100:end),'o')
% hold on
% plot(Xref2,Yref2,'ro')

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