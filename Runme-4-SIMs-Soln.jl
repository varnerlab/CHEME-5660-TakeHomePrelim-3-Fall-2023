include("Include.jl")

function main(; risk_free_rate::Float64 = 0.05, Δt::Float64 = (1.0/252.0), 
    groupname::String = "NewCo", enddate::Date = Date(2023,01,01))::Nothing

    # initialize -
    sim_model_dictionary = Dict{String, MySingleIndexModel}();

    # load and clean the data -
    dataset = _loadandcleandata(enddate = enddate);

    # get the tickers -
    all_tickers = keys(dataset) |> collect |> sort;

    # compute the excess return for all firms -
    all_firms_excess_return_matrix = _log_return_matrix(dataset, all_tickers, 
        Δt = Δt, risk_free_rate = risk_free_rate);

    # get data for the market -
    index_spy = findfirst(x->x=="SPY",all_tickers);
    Rₘ = all_firms_excess_return_matrix[:,index_spy];

    # Phase 1: estimate the SIM model parameters -
    for asset_ticker ∈ all_tickers
    
        # compute the excess return for asset_ticker -
        asset_ticker_index = findfirst(x->x==asset_ticker, all_tickers);
        Rᵢ = all_firms_excess_return_matrix[:, asset_ticker_index];
        
        # formulate the Y and X arrays with the price data -
        max_length = length(Rᵢ);
        Y = Rᵢ;
        X = [ones(max_length) Rₘ];
        
        # compute θ -
        θ = inv(transpose(X)*X)*transpose(X)*Y
        
        # package -
        sim_model = MySingleIndexModel();
        sim_model.α = θ[1];
        sim_model.β = θ[2];
        sim_model.r = risk_free_rate;
        sim_model_dictionary[asset_ticker] = sim_model;
    end

    # Phase 2: estimate the residual distribution for each firm -
    for asset_ticker ∈ all_tickers
    
        # grab the model -
        sim_model = sim_model_dictionary[asset_ticker];
        
        # compute the excess return for asset_ticker -
        asset_ticker_index = findfirst(x->x==asset_ticker, all_tickers);
        Rᵢ = all_firms_excess_return_matrix[:, asset_ticker_index];
        
        # compute the model excess return -
        αᵢ = sim_model.α
        βᵢ = sim_model.β
        R̂ᵢ = αᵢ .+ βᵢ .* Rₘ
        
        # compute the residual -
        Δᵢ = Rᵢ .- R̂ᵢ;
        
        # Esimate a distribution -
        d = fit_mle(Normal, Δᵢ);
        
        # update the sim_model -
        sim_model.ϵ = d;
    end

    # Phase 3: save the SIM models to disk -
    path_to_save_file = joinpath(_PATH_TO_DATA,"SIMs-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2");
    save(path_to_save_file, Dict("sims"=>sim_model_dictionary));

    # return -
    return nothing;
end

# TODO: specify the groupname -
groupname = "PortfolioDriftExample";
# run the main function -
main(groupname = groupname, enddate = Date(2023,01,01));