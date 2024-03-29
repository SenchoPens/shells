{
  description = "JupyterLab flake";

  inputs = {
      jupyterWith.url = "github:tweag/jupyterWith/old";
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs?rev=5e47a07e9f2d7ed999f2c7943b0896f5f7321ca3";
      nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, jupyterWith, flake-utils, nixpkgs-unstable }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
          overlays = nixpkgs.lib.attrValues jupyterWith.overlays;
          # config = { allowBroken = true; allowUnsupportedSystem = true; };
        };

        pkgs-unstable = import nixpkgs-unstable {
          system = system;
        };

        latexBuild = p: (p.texlive.combine {
          inherit (p.texlive)
            scheme-small collection-langcyrillic preprint invoice environ
            collection-fontsrecommended collection-latexrecommended latexmk tcolorbox
            type1cm dvipng  # for matplotlib
            # titlesec fontawesome yfonts gauss bbm listings physics
            # biblatex csquotes
          ;
        });

        latexShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ 
            # biber
            (latexBuild pkgs)
          ];
        };

        iPython = pkgs.kernels.iPythonWith {
          name = "Python-env";
          packages = p: with p;
          let
	      pytorch = callPackage ./pytorch {
		      cudaSupport = false;
		      inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices;
		      inherit (pkgs.darwin) libobjc;
	      };
              tqdm = callPackage ./tqdm.nix { };
              metric-learn = callPackage ../metric-learn.nix { };
          in [
            numpy

            pandas
            openpyxl
            tabulate  # for .to_markdown()

            (sentencepiece.override { inherit (pkgs-unstable) sentencepiece;})
            matplotlib
            seaborn
            folium  # map visualization

            scipy
            scikit-learn
            (torchvision.override { inherit pytorch; })
            metric-learn

            ipywidgets
            tqdm
            networkx
            pydot

            (nltk.override {inherit tqdm; })
            wordcloud
            # (optuna.override { inherit tqdm; })
            # optuna

            # bokeh
            # holoviews
            # panel
          ];
          ignoreCollisions = true;
        };

        jupyterEnvironment = pkgs.jupyterlabWith {
          kernels = [
            iPython
          ];
          extraPackages = p: [
            (latexBuild p)
            pkgs.sentencepiece
          ];
          # jupytext?

          # related issues about serverextensions:
          # https://github.com/tweag/jupyterWith/issues/131

          # needed for bokeh: https://github.com/bokeh/jupyter_bokeh
          # (from bokeh docs: https://docs.bokeh.org/en/latest/docs/user_guide/jupyter.html?highlight=jupyterlab)

          # extraJupyterPath = p:
          #   "${p.python3Packages.pyviz-comms}/lib/python3.9/site-packages:${p.python3Packages.";

          ###

          # not needed
          # extraJupyterPath = p: let lb = latexBuild p; in
          #   builtins.trace "${lb}" "${lb}";
        };

        mergeEnvs = envs: pkgs.mkShell (builtins.foldl' (a: v: {
          buildInputs = a.buildInputs ++ v.buildInputs;
          nativeBuildInputs = a.nativeBuildInputs ++ v.nativeBuildInputs;
          propagatedBuildInputs = a.propagatedBuildInputs ++ v.propagatedBuildInputs;
          propagatedNativeBuildInputs = a.propagatedNativeBuildInputs ++ v.propagatedNativeBuildInputs;
          shellHook = a.shellHook + "\n" + v.shellHook;
        }) (pkgs.mkShell {}) envs);

      in rec {
        packages = rec {
          jupyterlab = jupyterEnvironment;
          # default = jupyterlab;
        };

        apps = rec {
          jupyterlab = {
            type = "app";
            program = "${jupyterEnvironment}/bin/jupyter-lab";
          };
          pythonda = {
            type = "app";
            program = "${builtins.head iPython.runtimePackages}/bin/python-Python-env";
          };
          default = jupyterlab;
        };

        devShell = mergeEnvs [ jupyterEnvironment.env latexShell ];
        # devShell = mergeEnvs [ jupyterEnvironment.env ];
      }
    );
}
