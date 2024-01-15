function [eps_delta, eps_inf] = simplified_debye_fit(eps_r, tand, kappa, freq)

physical_constants;

omega = 2*pi*freq;
tau = 1./omega;

A = [(tand - omega' * tau)./(1 + (omega' * tau).^2), tand*ones([length(omega),1]); ones([1, 1+length(omega)])];
b = [kappa./(EPS0*omega), eps_r]';

x = linsolve(A,b);
eps_delta = x(1:length(x)-1);
eps_inf = x(end);
