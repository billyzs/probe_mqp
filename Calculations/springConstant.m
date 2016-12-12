clc; clear all; close all;
E = 0.16; % N/um2

L_BC = 6; % um
L_CD = 55.5 / 2; % um
L_AB = L_CD;
b = 2.5; % um
h = 3; % um
Ab = b * h; % um2
A_c = Ab; % um2
G = 0.69; % N/um2
I_by = h*b^3/12;
I_bx = b*h^3/12;
I_bz = 0;
I_cy = h*b^3/12;
I_cz = b*h^3/12;
c1 = 0.208;
J_c = c1*b*h^3;
J_b = c1*b*h^3;
A_b = b*h;

k_middle =  1 / ((L_AB^3-3*L_AB^2*L_CD + 3*L_AB*L_CD^2) / (3*E*I_bx) ...
    + 6*L_AB/ (5*G*A_b) + (L_BC^2*L_AB) / (G*J_b) + L_BC^3/(3*E*I_cz) ...
    + (6*L_BC) / (5*G*A_c) + (L_CD^2*L_BC) / (G*J_c) + L_CD^3/(3*E*I_bx) ...
    + 6*L_CD/(5*G*A_b));

L_CD = L_CD * 2;
k_edge = 1 / ((L_AB^3-3*L_AB^2*L_CD + 3*L_AB*L_CD^2) / (3*E*I_bx) ...
    + 6*L_AB/ (5*G*A_b) + (L_BC^2*L_AB) / (G*J_b) + L_BC^3/(3*E*I_cz) ...
    + (6*L_BC) / (5*G*A_c) + (L_CD^2*L_BC) / (G*J_c) + L_CD*0.05^3/(3*E*I_bx) ...
    + 6*L_CD/(5*G*A_b)); 

k_spring = 1 / (15/k_middle + 2/k_edge); 

k_ef = 8*k_spring;
max_force = 0.001; % N
displacement = max_force / k_ef; %max displacement before probe breakes;
force_probe_res = 0.05; % uN
distance_resulution = force_probe_res / 1000 / 1000 / k_ef; % 

k_ef

