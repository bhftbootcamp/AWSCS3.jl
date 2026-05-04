using AWSCS3
using Documenter

DocMeta.setdocmeta!(AWSCS3, :DocTestSetup, :(using AWSCS3); recursive = true)

makedocs(;
    modules = [AWSCS3],
    sitename = "AWSCS3.jl",
    format = Documenter.HTML(;
        repolink = "https://github.com/bhftbootcamp/AWSCS3.jl",
        canonical = "https://bhftbootcamp.github.io/AWSCS3.jl",
        edit_link = "master",
        assets = String["assets/favicon.ico"],
        sidebar_sitename = true,
    ),
    pages = [
        "Home" => "index.md",
        "API Reference" => "pages/api_reference.md",
    ],
    warnonly = [:doctest, :missing_docs],
)

deploydocs(;
    repo = "github.com/bhftbootcamp/AWSCS3.jl",
    devbranch = "master",
    push_preview = true,
)
