function SFO_Supply_Curve_v1
%----------------------------------------------------------------------------------------------
% Generate the supply curve under an SFO
%----------------------------------------------------------------------------------------------
foods           =  {'bananas','bread','milk','vegetable','beans'};
y_demand_ints   =  [ 7.75 8.65 7.75 9.15 6.75 ];
x_demand_ints   =  [ 2 4 5.5 3.5 5];
y_demand_slopes = - y_demand_ints ./ x_demand_ints;
n_lifes         =  [ 1    3    4    2    3    ];
s_ordinances    =  [ 10   10   10   10   10   ]/2;
c_stores        =  [ 0.3  2.4  1.2  1.1  1    ];
s_infra         =    3;
c_storages      =  [ 0.19 0.55 0.65 0.33 0.52 ] - [ 0.04 0.10 0.09 0.05 0.08 ]*s_infra;

fprintf('\n\nSFO RESULTS\n\n  price     profit resupply  food\n')
for k=1:5
    [ c_cust(k),y_resupply(k),m_profit(k) ] = fSFO_Supply_Curve_v1( ...
        y_demand_ints(k),y_demand_slopes(k),n_lifes(k),s_ordinances(k),...
        c_stores(k),c_storages(k),0 );
    fprintf('$%6.2f   $%7.2f        %i  %s\n',c_cust(k),m_profit(k),round(y_resupply(k)),foods{k})
end
% 
% for i = 1:10
%     [ c_cust(k),y_resupply(k),m_profit(k) ] = fSFO_Supply_Curve_v1( ...
%         y_demand_ints(k),y_demand_slopes,n_lifes,s_ordinances,...
%         c_stores,c_storages,0 );
% end
figure
plot(c_cust,y_resupply);

%----------------------------------------------------------------------------------------------
% USED FOR DEBUGGING AND EXMINING PLOTS
%----------------------------------------------------------------------------------------------
flag_plot = 1;                                           % 0:no plot, 1:show plot
max_plots = 5;                                           % maximum number of plots 
for k=1:max_plots
    fSFO_Supply_Curve_v1( ...
        y_demand_ints(k),y_demand_slopes(k),n_lifes(k),s_ordinances(k),...
        c_stores(k),c_storages(k),flag_plot,max_plots,k,foods{k} );
end
%----------------------------------------------------------------------------------------------


function [ c_cust,y_resupply,m_profit ] = fSFO_Supply_Curve_v1( ...
    y_demand_int,y_demand_slope,n_life,s_ordinance,c_store,c_storage,...
    flag_plot,max_plots,num_plot,lbl )
%----------------------------------------------------------------------------------------------
% Calculate the supply curve under an SFO
%----------------------------------------------------------------------------------------------
% INPUT
% y_demand_int   = y-intercept of the customer demand curve
% y_demand_slope = slope of the customer demand curve (must be negative)
% n_life         = number of weeks of shelf life
%                    (e.g., n_life = 2 => food can be kept for 2 weeks)
% s_ordinance    = minimum stock required at the beginning of the week
% c_store        = cost of unit food from supplier (including delivery charges)
% c_storage      = cost of food storage for one week
% flag_plot      = flag for plotting (set to 0 unless you want to examine the plots)
%----------------------------------------------------------------------------------------------
% OPTIONAL INPUT (needed only if flag_plot = 1)
% max_plot       = maximum number of subplots
% num_plot       = plot number
% lbl            = plot label
%----------------------------------------------------------------------------------------------
% OUTPUT
% c_cust         = nx1 array of prices for customer
% y_resupply     = nx1 array of resupply amounts corresponding to c_cust
% m_profit       = nx1 array of profit values corresponding to c_cust
%----------------------------------------------------------------------------------------------
% Initialize
%----------------------------------------------------------------------------------------------
a          = -1/y_demand_slope;                      % negative reciprocal of the slope
c_cust_max =  y_demand_int*a;                        % maximum possible customer price

n          = 100;                                    % number of points for curves
c_custs    = linspace(0,c_cust_max,n)';              % initialize customer prices
profit     = zeros(n,3);                             % three possible profit values
y_demand   = y_demand_int + y_demand_slope*c_custs;  % customer demand

y_demand_opts = [                                    % compute optimal y_demand
    y_demand_int/2 - (c_store + c_storage)/a/2       %   using the maximization results
    y_demand_int/2 - (c_store            )/a/2
    y_demand_int/2
    s_ordinance                                      %   at the boundaries
    s_ordinance/n_life ];

c_cust_opts = interp1(y_demand,c_custs,y_demand_opts);  % find the corresponding optimal prices

profit(:,1) = (c_custs - c_store - c_storage).*y_demand;        % calculate profit curves
profit(:,2) = (c_custs - c_store            ).*y_demand ...     % for cases k=1,2,3
    - c_storage*s_ordinance;
profit(:,3) = (c_custs - c_store            ).*y_demand ...
    - c_storage*s_ordinance ...
    - c_store*( s_ordinance/n_life - y_demand);
profit_valid = min(profit,[],2);

for k=1:5                                                       % find the optimal profit
    if k<=3, K = k; else K = 2; end                             % use case k=2 curves for k=4,5
    profit_opts(k) = interp1(c_custs,profit(:,K),c_cust_opts(k))';
end

if y_demand_opts(1) > s_ordinance
    k_opt = 1;
elseif s_ordinance > y_demand_opts(2) && y_demand_opts(2) >= s_ordinance/n_life
    k_opt = 2;
elseif s_ordinance/n_life > y_demand_opts(3)
    k_opt = 3;
elseif profit_opts(4) > profit_opts(5)
    k_opt = 4;
else
    k_opt = 5;
end

m_profit   = profit_opts(k_opt);
c_cust     = c_cust_opts(k_opt);
y_demand_opt = y_demand_opts(k_opt);
y_resupply   = max(y_demand_opt,s_ordinance/n_life);

if flag_plot
    cols = {'k','b','r'};               % colors and symbols for the three cases (k=1,2,3)
    syms = {'o','x','+'};
    
    fig  = figure(99); if num_plot==1, clf; end, fig.Name = 'Profit curves';
    
    subplot(2,max_plots,num_plot)
    plot(    c_custs,       profit_valid,  'y-','LineWidth',3), hold on 
    for k=1:3                                                        % for each case
        plot(c_custs,       profit(:,k),   [cols{k} '-'    ],...       
             c_cust_opts(k),profit_opts(k),[cols{k} syms{k}]),       % plot profit
    end
    plot(c_cust,m_profit,'k*'), hold off
    ylabel('profit'), title(lbl)
    
    subplot(2,max_plots,max_plots+num_plot)                          % plot demand curve
    for k=1:3
        plot(c_cust_opts(k),y_demand_opts(k),[cols{k} syms{k}]), hold on % show optimal results
    end
    plot(c_custs,y_demand,'k-',[0 c_cust_max],[1 ; 1]*[1 1/n_life]*s_ordinance,'k--')
    plot(c_cust, y_demand_opt, 'k*'), hold off
    xlabel('c_{cust} (price)'), ylabel('y_{demand}')
    if num_plot==3, legend('unconstrained','no waste','waste'), end
end


function c_cost_value = calc_c_cost(c_cust,y_demand,y_demand_value)
%----------------------------------------------------------------------------------------------
% calculate the c_cost corresponding to y_demand_value
%----------------------------------------------------------------------------------------------
c_cost_value = interp1(y_demand,c_cust,y_demand_value);