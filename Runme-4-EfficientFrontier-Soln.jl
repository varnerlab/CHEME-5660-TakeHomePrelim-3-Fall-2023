# setup -
include("Include.jl")


function main(; risk_free_rate::Float64 = 0.05, Δt::Float64 = (1.0/252.0), 
    groupname::String = "NewCo", enddate::Date = Date(2023,01,01), 
    my_list_of_tickers::Array{String,1} = ["AMD"], number_of_points = 100, 
    maxreturn = 0.5)::Nothing

    # initialize -
    μ_sim = Array{Float64,1}();
    my_list_of_firm_ids = Array{Int64,1}();
    efficient_frontier_sim = Dict{Float64,Float64}();
    portfolio_df = DataFrame();
    filepath = joinpath(_PATH_TO_DATA, "EfficientFrontier-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2");
    number_of_firms = length(my_list_of_tickers);
    wₒ = zeros(number_of_firms);
    wₒ[1] = 1.0;
    bounds = zeros(number_of_firms,2);
    bounds[:,2] .= 1.0;
    minimum_desired_reward_array = range(0.0, stop = maxreturn - risk_free_rate, length = number_of_points) |> collect;
  
    # load and clean the data -
    dataset = _loadandcleandata(enddate = enddate);

    # load the SIMs archive -
    sims = _loadmysimsarchive(enddate = enddate, groupname = groupname);

    # get the tickers -
    all_tickers = keys(dataset) |> collect |> sort;

    # compute the excess return for all firms -
    all_firms_excess_return_matrix = _log_return_matrix(dataset, all_tickers, 
        Δt = Δt, risk_free_rate = risk_free_rate);

    # compute mean excess return for all firms -
    μ = mean(all_firms_excess_return_matrix, dims=1) |> vec;

    # get expected excess data for the market -
    index_SPY = findfirst(x->x=="SPY", all_tickers);
    R_SPY = μ[index_SPY];
    σₘ = std(all_firms_excess_return_matrix[:, index_SPY]);

    # computed the expected excess return for all firms -
    for i ∈ eachindex(all_tickers)
    
        myticker = all_tickers[i];
        sim = sims[myticker];
    
        αᵢ = sim.α
        βᵢ = sim.β
        Rᵢ = αᵢ+βᵢ*R_SPY
    
        push!(μ_sim,Rᵢ)
    end

    # compute the covariance matrix for all firms
    Σ_tmp = Array{Float64,2}(undef, length(μ), length(μ));
    for i ∈ eachindex(all_tickers)
        outer_ticker = all_tickers[i];
        sim_outer = sims[outer_ticker];
        
        for j ∈ eachindex(all_tickers)
            
            inner_ticker = all_tickers[j];
            sim_inner = sims[inner_ticker];
            
            if (i == j)
                βᵢ = sim_outer.β
                ϵᵢ = sim_outer.ϵ
                σ_ϵᵢ = params(ϵᵢ)[2];
                Σ_tmp[i,j] = ((βᵢ)^2)*((σₘ)^2)+(σ_ϵᵢ)^2
            else
                βᵢ = sim_outer.β
                βⱼ = sim_inner.β
                Σ_tmp[i,j] = βᵢ*βⱼ*(σₘ)^2
            end
        end
    end
    Σ_sim  = Σ_tmp |> x-> x*(1/252);

    # Get the ids for the tickers in my_list_of_tickers -
    for ticker ∈ my_list_of_tickers
        firm_index = findfirst(x->x==ticker, all_tickers);    
        push!(my_list_of_firm_ids, firm_index)
    end

    # Get the μ̂_sim vector (expected excess return) for my_list_of_tickers -
    μ̂_sim = Array{Float64,1}();
    for firm_index ∈ my_list_of_firm_ids
        push!(μ̂_sim, μ_sim[firm_index])
    end

    # Get the Σ̂_sim matrix (covariance matrix) for my_list_of_tickers -
    my_number_of_selected_firms = length(my_list_of_firm_ids)
    Σ̂_sim = Array{Float64,2}(undef, my_number_of_selected_firms, my_number_of_selected_firms);
    for i ∈ eachindex(my_list_of_firm_ids)
        row_firm_index = my_list_of_firm_ids[i]
        for j ∈ eachindex(my_list_of_firm_ids)
            col_firm_index = my_list_of_firm_ids[j]
            Σ̂_sim[i,j] = Σ_sim[row_firm_index, col_firm_index]
        end
    end

    # build the problem object - initialize with the minimum desired excess reward, e.g., zero
    problem_risk_sim = build(MyMarkowitzRiskyAssetOnlyPortfiolioChoiceProblem, (
        Σ = Σ̂_sim,
        μ = μ̂_sim,
        bounds = bounds,
        initial = wₒ,
        R = 0.0
    ));

    # compute the efficient frontier -
    for i ∈ eachindex(minimum_desired_reward_array)
        
        # update the problem object -
        problem_risk_sim.R = minimum_desired_reward_array[i];
        
        # compute -
        solution_sim = solve(problem_risk_sim)

        # check: did this converge?
        status_flag = solution_sim["status"];    
        if (status_flag == MathOptInterface.LOCALLY_SOLVED)
            key = sqrt(solution_sim["objective_value"]);
            value = solution_sim["reward"];
            efficient_frontier_sim[key] = value;
            
            w_opt = solution_sim["argmax"];
            
            # add data to portfolio_df -
            row_df = (
                expected_excess_return = value,
                risk = key,
                tickers = my_list_of_tickers,
                w = w_opt,
                risk_free_rate = risk_free_rate
            )
            push!(portfolio_df,row_df);
        end
    end

    # save the file -
    save(filepath, Dict("dataset"=>portfolio_df))
    

    # return -
    return nothing;
end

# TODO: specify the tickers in your portfolio -
mytickers = ["PFE", "MRK", "AMD", "MU", "INTC", "SPY"]; # UPDATE THIS LIST OF TICKERS

# TODO: specify the groupname -
groupname = "PortfolioDriftExample";

# run the main function -
main(groupname = groupname, enddate = Date(2023,01,01), my_list_of_tickers = mytickers);