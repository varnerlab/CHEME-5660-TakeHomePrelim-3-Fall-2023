include("Include.jl")

# TODO: specify the groupname -
groupname = "NewCo";

# load the efficient frontier data -
dataset = load(joinpath(_PATH_TO_DATA, "EfficientFrontier-$(groupname)-PD1-CHEME-5660-Fall-2023.jld2")) |> x->x["dataset"];

# plot -
p = plot();
plot!(dataset[:,:risk], dataset[:,:expected_excess_return], lw=3, label="Efficient Frontier", c=:red)
scatter!(dataset[:,:risk], dataset[:,:expected_excess_return], label="", c=:white, mec=:red, ms=3)
xlabel!("Annual Risk (portfolio standard deviation)", fontsize=18);
ylabel!("Annual Expected Excess Return", fontsize=18);

# save -
savefig(p, joinpath(_PATH_TO_FIGS, "EfficientFrontier-$(groupname)-PD1-CHEME-5660-Fall-2023.pdf"))