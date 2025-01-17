% TODO describe the purpose of this file,
% what is done if no test is performed, what is done of tests are
% performed?

% TODO many variables defined in this file are then used in the simulink models, read read from workspace.
% Both in functions and in blocks. There is no overview which they are in
% this file. This must be fixed. In simulink, make one block where values
% are read from workspace, from there, hidden connections to the places
% where they are used in Simulink.In this file, make clear which the
% variables are.



%% clear the possible remnant on previous running
set(0,'defaulttextinterpreter','none');
dbclear all; %Remove breakpoints
clear;
close all;
clc;

%% Simulation Settings and Bike and General Parameters
% Gravitational Acceleration
    gg = 9.81;
% Name of the model
    model = 'Main_bikesim';
% Simulation time
    sim_time = 400;
% Sampling Time
    Ts = 0.01; 
% First closest point selection in reference. Starts at 2 because the one 
% before closest is in the local reference as well
    ref_start_idx = 2; %end of page 64 of Lorenzo's thesis
% Horizon distance [m]
    hor_dis = 10; %tra cosa?

%Constant Speed [m/s]
     vv = 2.6;    

% Open the Simulink Model
    open([model '.slx']);
% Choose the solver
    set_param(model,'AlgebraicLoopSolver','TrustRegion');
% Choose The Bike - Options:'red', 'black', 'green', 'scooter' or 'plastic' 
    bike = 'red';
% Load the parameters of the specified bicycle
    bike_params = LoadBikeParameters(bike); 
% bike model (for Simulink)
    bike_model = 1; % 1 = non-linear model || 2 = linear model
% 0 = Don't run test cases & save measurementdata in CSV || 1 = run test cases || 2 = generate ref yourself
    Run_tests = 0; 
% Take estimated states from a specific time if wanted (0 == initial conditions are set to zero || 1 == take from an online test)
    init = 0;
    time_start = 14.001; % what time do you want to take (if init==1)
% When you have bad GPS signal:
% Set indoor to 1 when you run the bike indoor or you have bad GPS signal
    indoor = 0; % used in Simulink
% Set badGPS=1 to make the GPS signal steady from the beginning of the sim.
    badGPS = 0; % used in Simulink
% Set compare_flag=1 if you want to compare two simulation results
    compare_flag = 0;
% Activate gain scheduling for system matrices and gains that depend on the
% velocity. Implemented on Kalman Filter and Heading dot contribution transfer function
    scheduling = 0;
% Activate the interpolation for the gain scheduling instead of taking
% matrices for nearest speed. Normally yes.
    interpolation = 0;  % used in Simulink (you can only use interpolation if scheduling = 1)
    if scheduling==0, interpolation = 0; end  % must be 0 if no scheduling
% %% Initial states
% if init == 1
% disp('reading from file')
%     % data_lab = readtable('Logging_data\Test_session_14_06\data_8.csv');
% %    data_lab = readtable('Logging_data\Test_session_27_06\data_15.csv');
% 
%     %Delete the data before reseting the trajectory and obtain X/Y position
%     reset_traj = find(data_lab.ResetTraj==1,1,'last');
%     data_lab(1:reset_traj,:) = [];
%     longitude0 = deg2rad(11);
%     latitude0 = deg2rad(57);
%     Earth_rad = 6371000.0;
% 
%     X = Earth_rad * (data_lab.LongGPS_deg_ - longitude0) * cos(latitude0);
%     Y = Earth_rad * (data_lab.LatGPS_deg_ - latitude0);
% 
%     % Obtain the relative time of the data
% %     Y = round(X,N) 
%     data_lab.Time = round((data_lab.Time_ms_- data_lab.Time_ms_(1))*0.001, 4);
%     index = find(data_lab.Time == time_start);
% 
%     initial_state.roll = data_lab.StateEstimateRoll_rad_(index);
%     initial_state.roll_rate = data_lab.StateEstimateRollrate_rad_s_(index);
%     initial_state.steering = data_lab.StateEstimateDelta_rad_(index);
%     initial_state_estimate.x = data_lab.StateEstimateX_m_(index) - X(1);
%     initial_state_estimate.y = data_lab.StateEstimateY_m_(index) - Y(1);
%     initial_state_estimate.heading = data_lab.StateEstimatePsi_rad_(index);
% 
% elseif init == 0
%     initial_state.roll = deg2rad(0);
%     initial_state.roll_rate = deg2rad(0);
%     initial_state.steering = deg2rad(0);
%     initial_state.x = 1; %why 1 and not 0?
%     initial_state.y = 0;
%     initial_state.heading = deg2rad(0);
%     initial_pose=[initial_state.x; initial_state.y; initial_state.heading];
% else
%     disp('Bad initialization');
% end

%% Reference trajectory generation
%SHAPE options:sharp_turn, line, infinite, circle, ascent_sin, smooth_curve
type = 'infinite';
% Distance between points
ref_dis = 0.05;
% Number of reference points
N = 200; 
% Scale (only for infinite and circle)
scale = 40; 

% [Xref,Yref,Psiref] = Trajectory(Run_tests);

%[Xref,Yref,Psiref] = ReferenceGenerator(type,ref_dis,N,scale);


ref_dis = 0.3;
laps=4;
lL=30; % length of straigt segment between the turns
[Xref,Yref,Psiref] = ReferenceGenerator('roset',ref_dis,lL,laps);

% read trajectory from file
%[Xref,Yref,Psiref,Vref,ttt]=Refgeneration({'x','y','v'},'AATrajCorrectedSpeed.csv');
%[Xref,Yref,Psiref]=Refgeneration({'x','y','v'},'AATrajCorrectedSpeed.csv');
% ref_traj = [Xref,Yref,Psiref,Vref];

% Calculating time vector given a constant speed
%TODO this should probably be changed, vv is used now, Vref or ttt should be
% obtained differently
ttt=[0;sqrt((Xref(1:end-1)-Xref(2:end)).^2+(Yref(1:end-1)-Yref(2:end)).^2)/vv];
t_ref=cumsum(ttt);
ttt(1)=ttt(2); % avoid 0 sampling time
[Xref,Yref,Psiref,Vref]=Refgeneration({'t','x','y'},[t_ref, Xref,Yref]);

v_init=Vref(1); % needed for lqr, referenceTest, simulink>atateestimator

%test_curve=[Xref,Yref,Psiref];
Nn = length(Xref); % needed for simulink

%% OWN TRAJECTORY
% if Run_tests == 2
%[Xref,Yref,Psiref] = ReferenceGenerator(type,ref_dis,N,scale);
% test_traj();
% data = fileread('trajectory.txt');
% test_curve=[Xref,Yref,Psiref];
% Nn = size(test_curve,1); % needed for simulink
% end

%% Reference test (warnings and initialization update)
%if ((Run_tests == 0 || Run_tests == 2) && init == 0)
    %referenceTest(test_curve,hor_dis,Ts,initial_pose,v_init, ref_dis);
    referenceTest([Xref Yref Psiref],hor_dis,Ts,vv);
    
    % update initial states if offset is detected
    initial_state.x = Xref(1);
    initial_state.y = Yref(1);
    initial_state.heading = Psiref(1);

    initial_state.roll = deg2rad(0);
    initial_state.roll_rate = deg2rad(0);
    initial_state.steering = deg2rad(0);
    initial_pose=[initial_state.x; initial_state.y; initial_state.heading];

    initial_state_estimate = initial_state;
%end

%% Unpacked bike_params
[hh,lr,lf,lambda,cc,mm,h_imu,Tt]=UnpackBike_parameters(bike_params);

T = TransMatrix(bike_params);                                             

%% Disturbance Model
% 
% % Roll Reference  
% roll_ref_generation;%long time ago left by other students, it's helpless now but keep it
% 
% % Steering Rate State Perturbation
% pert_deltadot_state = 0; % Switch ON (1) / OFF (0) the perturbation
% pert_deltadot_state_fun = @(time)  -0.5*(time>10) && (ceil(mod(time/3,2)) == 1) &&(time<30);
% 
% % Roll Rate State Perturbation
% pert_phidot_state = 0; % Switch ON (1) / OFF (0) the perturbation
% pert_phidot_state_fun = @(time) cos(time)*(time>10 && time < 10.4);

%% Bike State-Space Model

% Continuous-Time Model

% % Controllable Canonical Form
%     A = [0 g/bike_params.h ; 1 0];
%     B = [1 ; 0];
%     C = [bike_params.a*v/(bike_params.b*bike_params.h) g*bike_params.inertia_front/(bike_params.h^3*bike_params.m)+v^2/(bike_params.b*bike_params.h)];
%     D = [bike_params.inertia_front/(bike_params.h^2*bike_params.m)];

% % Observable Canonical Form
%     A = [0 g/bike_params.h ; 1 0];
%     B = [g*bike_params.inertia_front/(bike_params.h^3*bike_params.m)+(v^2./(bike_params.b*bike_params.h)-bike_params.a*bike_params.c*g/(bike_params.b*bike_params.h^2)).*sin(bike_params.lambda) ;
%         bike_params.a*v/(bike_params.b*bike_params.h).*sin(bike_params.lambda)];
%     C = [0 1];
%     D = [bike_params.inertia_front/(bike_params.h^2*bike_params.m)];
% 
% % Linearized System
%     linearized_sys = ss(A,B,C,D);
% % Augmented System
%     fullstate_sys = ss(linearized_sys.A,linearized_sys.B,eye(size(linearized_sys.A)),0);
% % Discretized System
%     discretized_sys = c2d(linearized_sys,Ts);

%% Balancing Controller
%Remove I and D?
% Outer loop -- Roll Tracking
P_balancing_outer = 3.75;
I_balancing_outer = 0.0;
D_balancing_outer = 0.0;

% Inner loop -- Balancing
P_balancing_inner = 3.5;
I_balancing_inner = 0;
D_balancing_inner = 0; 


%% Calculating gains and matrices which depend on velocity, based on velocity vector which is created below. 
if scheduling
    V_min= min(Vref(:));
    V_max= max(Vref(:));
    V_min=min([V_min,V_max-0.3]); % This is to make sure there is a non-zero interval for the scheduling
    v_max=max([V_max, V_min+0.6]);  % This can be improved. Interval is set ad-hoc
    if (V_max-V_min)<0.05 
        disp('Warning, no speed variation in Vref, scheduling matrices becomes identical'); 
        disp('Simulation does not work in this case.');
    end
else % No scheduling, constant matrices calculated for one fixed speed
    V_min= Vref(2);
    V_max= V_min;
end


% construct vector of velocities for which linear Kalman filter is
% obtained, ie, matrices for each velocity
V_stepSize=0.1; % design choice

V_n=ceil((V_max-V_min)/V_stepSize)+1; % number of velocities for which linearized matrices are calculated.
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

% Q & R are calculated in a different file
load('Q_and_R_backup_red_bike.mat');

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

% TODO, where is this table used?
% Storing all the calculated matrices and gains.
GainsTable = table(V',K_GPS,K_noGPS,A_d,B_d,C,D, 'VariableNames', {'V','K_GPS','K_noGPS','A_d','B_d','C','D'});


% looks like the controller is not speed dependent, one fixed speed
%% The LQR controller
[k1,k2,e1_max,e2_max] = LQRcontroller(v_init,lr,lf);

%% Transfer function for heading in wrap traj
%feed forward transfer function for d_psiref to steering reference (steering contribution for heading changes)

% Discretize the ss 
% % Used in Simulink
Ad_t = eye(1)+Ts*A_t;% A_t and B_t are calculated on gains table section above.
Bd_t = B_t*Ts;


%% Save matrix in XML/CSV
% matrixmat = [A_d; B_d'; C; D';K_GPS; K_noGPS]; 
% SaveInCSV(matrixmat,test_curve);

linearizedMatrices=[Ad_t, Bd_t, C_t, D_t, V'];

%% Start the Simulation


if Run_tests == 0 || Run_tests == 2
tic
try 
    Results = sim(model); % If no error occurs, MATLAB skips the catch.
    catch error_details %note: the model has runned for one time here
end
toc

% Simulation Messages and Warnings
% if Results.stop.Data(end) == 1
%     disp('Message: End of the trajectory has been reached');
% end

%% Plotting
% If you want to compare two different simulation results, then change the
% name of 'bikedata_sim_real_states.csv' and 'bikedata_sim_est.csv' to
% 'bikedata_sim_real_states_1.csv' and 'bikedata_sim_est_1.csv after
% running main_sim.m the first time and change compare_flag to 1 before
% running main_sim.m the second time.
%PlottingResults(test_curve,Results,compare_flag);


Tnumber = 'No test case: General simulation run';
Plot_bikesimulation_results(Tnumber, [Xref,Yref,Psiref], Results, compare_flag);
end

%% Test cases for validation
TestCases(Run_tests,hor_dis,Ts,initial_pose);
%%
