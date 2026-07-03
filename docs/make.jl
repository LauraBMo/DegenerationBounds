using DegenerationBounds
using Documenter

DocMeta.setdocmeta!(DegenerationBounds, :DocTestSetup, :(using DegenerationBounds); recursive=true)

makedocs(;
    modules=[DegenerationBounds],
    authors="LauBMo <laurea987@gmail.com> and contributors",
    sitename="DegenerationBounds.jl",
    format=Documenter.HTML(;
        canonical="https://LauraBMo.github.io/DegenerationBounds.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LauraBMo/DegenerationBounds.jl",
    devbranch="main",
)
