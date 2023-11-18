include("Include.jl")

# TODO: specify the groupname -
groupname = "NewCo";

# load the efficient frontier data -
dataset_ef = load(joinpath(_PATH_TO_DATA, "EfficientFrontier-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2")) |> x->x["dataset"];
dataset_cal = load(joinpath(_PATH_TO_DATA, "CapitalAllocationLine-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2")) |> x->x["dataset"];


# plot -
p = plot();
plot!(dataset_ef[:,:risk], dataset_ef[:,:expected_excess_return], lw=3, label="Efficient Frontier", c=:red)
scatter!(dataset_ef[:,:risk], dataset_ef[:,:expected_excess_return], label="", c=:white, mec=:red, ms=3)
plot!(dataset_cal[:,:risk], dataset_cal[:,:expected_excess_return], lw=3, label="Capital Allocation Line", c=:blue)


xlabel!("Annual Excess Risk (portfolio standard deviation)", fontsize=18);
ylabel!("Annual Expected Excess Return", fontsize=18);

# save -
savefig(p, joinpath(_PATH_TO_FIGS, "CapitalAllocationLine-$(groupname)-PD1-CHEME-5660-Fall-2023.pdf"))