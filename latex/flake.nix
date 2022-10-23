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
          biber
          (texlive.combine { inherit (pkgs.texlive)
            bbm
            beamer
            biblatex
            bussproofs  # for proof trees, see https://www.actual.world/resources/tex/doc/Proofs.pdf
            collection-fontsrecommended
            collection-langcyrillic
            collection-latexrecommended
            csquotes
            environ
            fontawesome
            gauss
            invoice
            latexmk
            listings
            pgfopts
            pgfornament
            physics
            placeins
            preprint
            scheme-small
            sidecap
            tcolorbox
            titlesec
            tkz-graph
            trimspaces
            yfonts
            ;
          })
        ];
      };
    });
}
