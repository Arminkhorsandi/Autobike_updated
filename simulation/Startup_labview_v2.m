%% Version 2 of Startup_labview

% TODO a lot of code is doubled from Main_sim.m this should be removed and,
% probably put into separate functions which are called from respective
% file.

% This file generates parameters

% Update since ver1: 
% - Creates matrixmat including two sets of matrices and gains, based on 
%   the minimum and maximum velocities to be compatible with the new
%   version of labview where interpolation is used. Previous version
%   cannot be used to send matrixmat to myRIO if new version(after 15aug 2024)
%   of labview with interpolation is used.


%% clear the possible remnant on previous running
%clear;
close all;
clc;

%% Simulation Settings and Bike Parameters

% Choose The Bike - Options: 'red' or 'black'
    bike = 'red';
    biketype ='red_bike';
load('Q_and_R_backup_red_bike.mat'); % read Q and R used in the Kalman filter

% file where the reference trajectory can be read, on format according to
% Refgeneration.m". That format is presently used in simulation.
trajectotyfile='v26R30.csv';

% Store trajectory on format for Labview in the following file
trajectoryLabview='Rosetv26R30half.csv';

% Bike parameters for the specific reference trajectory are stored with
% indicated filename in directory given by "parameters4bike" \ "biketype"
parameters4bike='Parameters_matrixmat\';
filename_matrixmat='matrixmat';

% Choose trajectory, can be done using Main_sim, any other, m-file or reading from file
% Load trajectory file
%    [Xref,Yref,Psiref,Vref,t]=Refgeneration({'x','y','v'},trajectoryfile);


% General Parameters
% Gravitational Acceleration
    gg = 9.81;
% Sampling Time
    Ts = 0.01; 

% Load the parameters of the specified bicycle
    bike_params = LoadBikeParameters(bike);


% Constant Speed needed for lqr [m/s]
    v_init = Vref(1); 
    if abs(v_init-2.5)>1.7, disp('Warning: LQR lateral controler set for low/high speed'); end

% %% Initial states
% 
initial_X = Xref(1);
initial_Y = Yref(1);
initial_Psi = Psiref(1);
initial_roll = deg2rad(0);
initial_roll_rate = deg2rad(0);
initial_delta = deg2rad(0);
initial_v = 0;

initial_states = [initial_X,initial_Y,initial_Psi, initial_roll, initial_roll_rate, initial_delta, initial_v];

%% Unpacked bike_params

[hh,lr,lf,lambda,cc,mm,h_imu,Tt,r_wheel]=UnpackBike_parameters(bike_params);
% hh = bike_params.h;
% lr = bike_params.lr;
% lf = bike_params.lf; 
% lambda = bike_params.lambda;
% cc = bike_params.c;
% mm = bike_params.m;
% h_imu = bike_params.IMU_height; 
% r_wheel = bike_params.r_wheel; 

% TODO the follwing parameters should be set for each bike individualy, ie,
% move into m-file for the bikes.

%% Balancing Controller

% Outer loop -- Roll Tracking
P_balancing_outer = 3.75;
I_balancing_outer = 0.0;
D_balancing_outer = 0.0;

% Inner loop -- Balancing
P_balancing_inner = 3.5;
I_balancing_inner = 0;
D_balancing_inner = 0;  

%% The LQR controller for lateral controller
% model of lateral error  
A_con=[0 v_init;0 0];
B_con=[lr*v_init/(lr+lf);v_init/(lr+lf)];

%  kk=0.000000010;
%  kk=2.581e-7;
%  kk=9e-7;
 kk=6e-7;
%  Ql=kk*[100 0;0 1000];
 Ql=kk*[1000 0;0 100];
 Rl=0.2;
%  R=0.5;
 [K,S,e] = lqr(A_con,B_con,Ql,Rl);
 k1=K(1);
 k2=K(2);

e2_max=deg2rad(30);% Here is the e2_max we used to calculate e1_max
e1_max=abs(-k2*e2_max/k1); % k1,k2 has been known, so we can calculate e1_max

%% Calculating gains and matrices which depend on velocity, based on velocity vector which is created below. 
% For speed dependent Kalman filter
    V_min= min(Vref(:));
    V_max= max(Vref(:));
    V_min=min([V_min,V_max-0.3]); % This is to make sure there is a non-zero interval for the scheduling
    v_max=max([V_max, V_min+0.6]);  % This can be improved. Interval is set ad-hoc
    if (V_max-V_min)<0.05 
        disp('Warning, no speed variation in Vref, scheduling matrices becomes identical'); 
        disp('Simulation does not work in this case.');
    end

V_stepSize=3;

V_n=ceil((V_max-V_min)/V_stepSize)+1;
V=linspace(V_min,V_max,V_n);

V=round(V,1);

K_GPS=zeros(V_n,7,7);
K_noGPS=zeros(V_n,7,7);


counter=zeros(V_n,1);
A_d=zeros(V_n,7,7);
B_d=zeros(V_n,7,1);
C=zeros(V_n,7,7);
D=zeros(V_n,7,1);

A_t=zeros(V_n,1);
B_t=zeros(V_n,1);
C_t=zeros(V_n,1);
D_t=zeros(V_n,1);



format long
for i=1: V_n
    % Kalman filtering for both cases - with/without GPS - 
    [K_GPS(i,:,:),K_noGPS(i,:,:),counter,A_d(i,:,:),B_d(i,:,:),C(i,:,:),D(i,:,:)] = KalmanFilter(V(i),hh,lr,lf,lambda,gg,cc,h_imu,Ts,Q,R);

    % Transfer function in heading in wrap traj
    num = 1;
    den = [lr/(lr+lf), V(i)/(lr+lf)];
    [A_t(i,:), B_t(i,:), C_t(i,:), D_t(i,:)] = tf2ss(num,den);
end
K_GPS=permute(K_GPS,[1,3,2]);
K_noGPS=permute(K_noGPS,[1,3,2]);
A_d=permute(A_d,[1,3,2]);
C=permute(C,[1,3,2]);

A_dMin = squeeze(A_d(1,:,:));
A_dMax = squeeze(A_d(2,:,:));

B_dMin = squeeze(B_d(1,:,:));
B_dMax = squeeze(B_d(2,:,:));

C_Min = squeeze(C(1,:,:));
C_Max = squeeze(C(2,:,:));

D_Min = squeeze(D(1,:,:));
D_Max = squeeze(D(2,:,:));

K_GPSMin = squeeze(K_GPS(1,:,:));
K_GPSMax = squeeze(K_GPS(2,:,:));

K_noGPSMin = squeeze(K_noGPS(1,:,:));
K_noGPSMax = squeeze(K_noGPS(2,:,:));
% Storing all the calculated matrices and gains.
% GainsTable = table(V',K_GPS,K_noGPS,A_d,B_d,C,D, 'VariableNames', {'V','K_GPS','K_noGPS','A_d','B_d','C','D'});

% Discretize the ss 
% % Used in Simulink ??? but also in LabView???
Ad_t = (eye(size(A_t))+Ts*A_t);   % A_t and B_t are calculated on gains table section above.
Bd_t = B_t*Ts;

Ad_tMin = 1+Ts*A_t(1);
Ad_tMax = 1+Ts*A_t(2);

Bd_tMin = Bd_t(1);
Bd_tMax = Bd_t(2);

C_tMin = C_t(1);
C_tMax = C_t(2);

D_tMin = D_t(1);
D_tMax = D_t(2);

%% Defineobject params on the format required by labview

% Matrix (3,7) of parameters
% TODO use the unpacked bike parameters, ie remove "bike_params."
params = zeros(3,7);
params(1,1) = bike_params.steer_motor_gear_rat;
params(1,2) = bike_params.steer_pully_gear_rat;
params(1,3) = bike_params.steer_enc_CPR;
params(1,4) = bike_params.steer_motor_max_RPM;
params(1,5) = bike_params.max_steer_angle;
params(1,6) = bike_params.drive_motor_gear_rat;
params(1,7) = bike_params.wheelbase;
params(2,1) = bike_params.fork_angle;
params(2,2) = bike_params.r_wheel;
params(2,3) = bike_params.lr;
params(2,4) = bike_params.lf;
params(2,5) = bike_params.lambda;
params(2,6) = k1;
params(2,7) = k2;
params(3,1) = e1_max;
params(3,2) = Ad_tMin;
params(3,3) = Bd_tMin;
params(3,4) = C_tMin;
params(3,5) = D_tMin;
params(3,6) = P_balancing_outer;
params(3,7) = P_balancing_inner;
params(4,1) = 0;
params(4,2) = Ad_tMax;
params(4,3) = Bd_tMax;
params(4,4) = C_tMax;
params(4,5) = D_tMax;
params(4,6) = V_min;
params(4,7) = V_max;


%% Save matrix in XML/CSV

% matrixmat = [A_d; B_d'; C1; D1';Kalman_gain1; K_noGPS;initial_states;params];
matrixmat = [A_dMin'; A_dMax'; B_dMin; B_dMax; C_Min'; C_Max'; D_Min; D_Max; K_GPSMin'; K_GPSMax'; K_noGPSMin'; K_noGPSMax'; initial_states;params];


prompt = {'Enter the bike type','Enter the matrix name.'};
dlgtitle = 'Parameters matrix';
dims = [1 40];
definput = {biketype,filename_matrixmat};
answer = inputdlg(prompt,dlgtitle,dims,definput);
biketype=string(answer{1,1});
filename=string(answer{2,1});
filename_matrix = strcat(parameters4bike,biketype,'\',filename,'.csv');
dlmwrite(filename_matrix, matrixmat, 'delimiter', ',', 'precision', 10);

csvwrite(trajectoryLabview,[Xref,Yref,Psiref,Vref])
