{
  description = "Description for the project";

  nixConfig.extra-substituters = [
    "https://tweag-jupyter.cachix.org"
  ];
  nixConfig.extra-trusted-public-keys = [
    "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g="
  ];

  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "nixpkgs-unstable";
    # jupyenv.url = "github:tweag/jupyenv";
    # jupyenv.url = "/home/sencho/n/git/github.com/SenchoPens/jupyterWith";
    jupyenv.rul = "https://github.com/SenchoPens/jupyterWith";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {
        config,
        lib,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        inherit (inputs.jupyenv.lib.${system}) mkJupyterlabNew;
        jupyterlab = mkJupyterlabNew (builtins.trace "Reevaluating JupyterLab" ({...}: {
          nixpkgs = inputs.nixpkgs;
          imports = [
            ({pkgs, ...}: {
              kernel.python.da = {
                enable = true;
                projectDir = ./.;
                python = "python311"; # pkgs.python311;
                groups = ["dev"];
                preferWheels = true;
              };
            })
          ];
        }));
      in {
        devShells = {
          # Source code development shell:
          # formatters, checkers / linters, poetry CLI, etc.
          default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.poetry
              jupyterlab
            ];
          };
        };

        apps = {
          jupyterlab = {
            type = "app";
            program = "${jupyterlab}/bin/jupyter-lab";
          };
          poetry = {
            type = "app";
            program = "${pkgs.poetry}/bin/poetry";
          };
        };
      };
    };
}
