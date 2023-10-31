{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication defaultPoetryOverrides;
      in
      {
        packages = {
          myapp = mkPoetryApplication {
            projectDir = ./.;
            overrides = defaultPoetryOverrides.extend
              (self: super: {
                faiss-cpu = super.faiss-cpu.overridePythonAttrs
                  (
                    old: {
                      doCheck = false;
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools super.faiss super.setuptools-rust ];
                      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.swig4  ];
                    }
                  );
                tiktoken = super.tiktoken.overridePythonAttrs
                  (
                    old: {
                      doCheck = false;
                      HOME="/tmp";
                      nativeBuildInputs = [ pkgs.cargo pkgs.rustc ];
                      buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools-rust  ];
                    }
                  );
              });
          };
          default = self.packages.${system}.myapp;
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.poetry ];
        };
      });
}
