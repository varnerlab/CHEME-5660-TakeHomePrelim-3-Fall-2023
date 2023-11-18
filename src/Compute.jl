function _log_return_matrix(dataset::Dict{String, DataFrame}, 
    firms::Array{String,1}; Δt::Float64 = (1.0/252.0), risk_free_rate::Float64 = 0.0)::Array{Float64,2}

    # initialize -
    number_of_firms = length(firms);
    number_of_trading_days = nrow(dataset["AAPL"]);
    return_matrix = Array{Float64,2}(undef, number_of_trading_days-1, number_of_firms);

    # main loop -
    for i ∈ eachindex(firms) 

        # get the firm data -
        firm_index = firms[i];
        firm_data = dataset[firm_index];

        # compute the log returns -
        for j ∈ 2:number_of_trading_days
            S₁ = firm_data[j-1, :volume_weighted_average_price];
            S₂ = firm_data[j, :volume_weighted_average_price];
            return_matrix[j-1, i] = (1/Δt)*log(S₂/S₁) - risk_free_rate;
        end
    end

    # return -
    return return_matrix;
end

function _loadandcleandata(;enddate::Date = Date(2023,01,01))::Dict{String,DataFrame}

    # initialize -
    dataset = Dict{String,DataFrame}();

    # load the original dataset
    original_dataset = MyPortfolioDataSet() |> x-> x["dataset"]

    # what is the maximum number of days in the dataset?
    maximum_number_trading_days = original_dataset["AAPL"] |> nrow;

    # clean the dataset -
    for (ticker,data) ∈ original_dataset
        if (nrow(data) == maximum_number_trading_days)

            # filter the data - we only want data from 2018 to 2022 -
            dataset[ticker] = filter(:timestamp => x->x < enddate, data);
        end
    end

    # return -
    return dataset;
end

function _loadmysimsarchive(;enddate::Date = Date(2023,01,01), 
    groupname::String = "NewCo")::Dict{String, MySingleIndexModel}
    
    # load the archive -
    myarchive = load(joinpath(_PATH_TO_DATA, "SIMs-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2")) |> x->x["sims"];
    
    # return -
    return myarchive;
end
