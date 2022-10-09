{
  description = "Latex Flake";
  # Provides abstraction to boiler-code when specifying multi-platform outputs.
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ 
          (texlive.combine { inherit (pkgs.texlive)
            scheme-small collection-langcyrillic preprint invoice environ
            collection-fontsrecommended collection-latexrecommended latexmk tcolorbox
            titlesec
            fontawesome yfonts bbm
            gauss
            listings
            pgfornament pgfopts
            physics
            bussproofs  # for proof trees, see www.actual.world/resources/tex/doc/Proofs.pdf
            tkz-graph
            biblatex csquotes sidecap placeins beamer
            ;
          })
        ];
      };
    });
}
