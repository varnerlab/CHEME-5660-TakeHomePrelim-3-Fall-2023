# setup paths -
const _ROOT = pwd();
const _PATH_TO_SRC = joinpath(_ROOT, "src");
const _PATH_TO_DATA = joinpath(_ROOT, "data");
const _PATH_TO_FIGS = joinpath(_ROOT, "figs");

# load external packages -
import Pkg;
import Pkg; Pkg.activate("."); Pkg.resolve(); Pkg.instantiate(); Pkg.update();
using DataFrames
using CSV
using JLD2
using FileIO
using Statistics
using Distributions
using Dates
using MadNLP
using JuMP
using MathOptInterface
using Plots
using Colors

# load my codes -
include(joinpath(_PATH_TO_SRC, "Types.jl"));
include(joinpath(_PATH_TO_SRC, "Factory.jl"));
include(joinpath(_PATH_TO_SRC, "Files.jl"));
include(joinpath(_PATH_TO_SRC, "Compute.jl"));
include(joinpath(_PATH_TO_SRC, "Solve.jl"));
