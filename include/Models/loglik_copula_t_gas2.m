function [LL, f, rho] = loglik_copula_t_gas2(theta, y)
    [N,~] = size(theta);
    T = size(y, 1);
    
    omega = theta(:,1);
    A = theta(:,2);
    B = theta(:,3);
    nu = theta(:,4);
    
    f = zeros(N,T);  % alpha in the paper, time-varying parameter following GAS recursion
    f(:,1) = omega./(1-B); 
%     transf = @(aa) (1 - exp(-aa))./(1 + exp(-aa));
    rho = zeros(N,T); % the time-varying parameter tranfsormed by the trnasf function --> rho, i.e. the correlation
    rho(:,1) = transf(f(:,1));
    
    LL = zeros(N,1);
    
%     scoref = @(z1, z2, r, w) ((1 + r.^2).*(w.*z1.*z2 - r) - r.*(w.*z1.^2 + w.*z2.^2 - 2))./((1 - r.^2).^2);
%     inff = @(r, v) (v + 2 + v.* r.^2)./((v+4).*(1 - r.^2).^2);
%     wf = @(z1, z2, r, v) (v + 2)./(v + (z1.^2 + z2.^2 - 2*r.*z1.*z2)./(1 - r.^2)) ;
    
    for ii = 1:N
        z = tinv(y,nu(ii,1));
        for jj = 2:T
            w = wf(z(jj-1,1), z(jj-1,2), rho(ii,jj-1), nu(ii,1));
%             fprintf('w = %6.4f\n', w);
            s = scoref(z(jj-1,1), z(jj-1,2), rho(ii,jj-1), w);
            scscore = s./sqrt(inff(rho(ii,jj-1), nu(ii,1)));
            f(ii,jj) = omega(ii,1) + A(ii,1).*scscore + B(ii,1).*f(ii,jj-1);
            rho(ii,jj) = transf(f(ii,jj));        
        end

        Z1 = z(:,1)';
        Z2 = z(:,2)'; 
       
        L = log(gamma((nu(ii,1)+2)/2)) + log(gamma(nu(ii,1)/2)) - 2*log(gamma((nu(ii,1)+1)/2)) ...
            - 0.5*log(1-rho(ii,:).^2) ...
            - 0.5*(nu(ii,1)+2).*log(1 + (Z1.^2 + Z2.^2 - 2*rho(ii,:).*Z1.*Z2)./(nu(ii,1).*(1 - rho(ii,:).^2))) ...
            + 0.5*(nu(ii,1)+1).*log(1 + (Z1.^2)./nu(ii,1)) ...
            + 0.5*(nu(ii,1)+1).*log(1 + (Z2.^2)./nu(ii,1));
        LL(ii,1) = -sum(L,2)/T;
    end
%     f_T = f(:,T);
%     rho_T = rho(:,T);
end

function w = wf(z1, z2, r, v) 
    w = (v + 2)./(v + (z1.^2 + z2.^2 - 2*r.*z1.*z2)./(1 - r.^2)) ;
end

function s = scoref(z1, z2, r, w) 
    s =  ((1 + r.^2).*(w.*z1.*z2 - r) - r.*(w.*z1.^2 + w.*z2.^2 - 2))./((1 - r.^2).^2);
end

function invf = inff(r, v) 
    invf =  (v + 2 + v.* r.^2)./((v+4).*(1 - r.^2).^2);
end

function aa = transf(aa)
    aa = (1 - exp(-aa))./(1 + exp(-aa));
end