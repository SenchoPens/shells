{
  description = "JupyterLab flake";

  inputs = {
      jupyterWith.url = "github:tweag/jupyterWith";
      flake-utils.url = "github:numtide/flake-utils";
      nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.11";
  };

  outputs = { self, nixpkgs, jupyterWith, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
          overlays = nixpkgs.lib.attrValues jupyterWith.overlays;
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
          nativeBuildInputs = [ 
            # biber
            (latexBuild pkgs)
          ];
        };

        iPython = pkgs.kernels.iPythonWith {
          name = "Python-env";
          packages = p: with p; [
            numpy

            pandas
            openpyxl
            tabulate  # for .to_markdown()

            matplotlib
            seaborn
            folium  # map visualization

            scipy
            scikit-learn
            # (callPackage ./metric-learn.nix { })
            # scikit-learn-extra
            # pytorch
            # torchvision
            # transformers

            ipywidgets
            tqdm
            networkx
            pydot

            sentencepiece
            pymorphy2
            nltk
            (wordcloud.overrideAttrs (old: { doCheck = false; doInstallCheck = false; }))

            catboost
            imbalanced-learn
            joblib
            # umap-learn
            # music21

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

      in {
        packages = rec {
          jupyterlab = jupyterEnvironment;
          default = jupyterlab;
        };

        apps = rec {
          jupyterlab = {
            type = "app";
            program = "${jupyterEnvironment}/bin/jupyter-lab";
          };
          default = jupyterlab;
        };

        devShell = mergeEnvs [ jupyterEnvironment.env latexShell ];
      }
    );
}
