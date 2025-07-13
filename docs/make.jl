using InstanceDispatch
using Documenter

DocMeta.setdocmeta!(InstanceDispatch, :DocTestSetup, :(using InstanceDispatch); recursive = true)

makedocs(;
    modules = [InstanceDispatch],
    authors = "Hugo Levy-Falk <hugo@klafyvel.me> and contributors",
    sitename = "InstanceDispatch.jl",
    format = Documenter.HTML(;
        canonical = "https://klafyvel.github.io/InstanceDispatch.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo = "github.com/Klafyvel/InstanceDispatch.jl",
    devbranch = "main",
)
