{
  description = "Headroom - The Context Optimization Layer for LLM Applications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;

        headroom-ai = python.pkgs.buildPythonPackage rec {
          pname = "headroom-ai";
          version = "0.23.0";
          format = "pyproject";

          src = pkgs.fetchFromGitHub {
            owner = "chopratejas";
            repo = "headroom";
            rev = "v${version}";
            hash = "sha256-4pQUSi8dU85tm5WY8Z/ZEN8O/ccGDDVIC3SnNBvUZTY=";
          };

          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = ./Cargo.lock;
          };

          postPatch = ''
            substituteInPlace crates/headroom-core/Cargo.toml \
              --replace-fail '"ort-download-binaries-rustls-tls"' '"ort-load-dynamic"'
          '';

          nativeBuildInputs = with pkgs; [
            rustPlatform.maturinBuildHook
            rustPlatform.cargoSetupHook
            cargo
            rustc
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
          ];

          propagatedBuildInputs = with python.pkgs; [
            # core
            tiktoken
            pydantic
            click
            rich
            litellm
            opentelemetry-api
            tomli
            # proxy (imported unconditionally at CLI startup)
            fastapi
            uvicorn
            httpx
            websockets
            watchdog
            zstandard
            openai
            mcp
            sqlite-vec
            magika
          ] ++ [
            pkgs.onnxruntime
          ];

          passthru.withML = headroom-ai.overridePythonAttrs (old: {
            propagatedBuildInputs = old.propagatedBuildInputs ++ [ python.pkgs.transformers ];
          });

          pythonRelaxDeps = true;

          # ast-grep-cli PyPI package bundles the binary; use the native nixpkgs package instead
          pythonRemoveDeps = [ "ast-grep-cli" ];

          makeWrapperArgs = [ "--prefix" "PATH" ":" "${pkgs.ast-grep}/bin" ];

          doCheck = false;
        };
      in
      {
        packages.default = headroom-ai;
        packages.headroom-ai = headroom-ai;
        packages.headroom-ai-ml = headroom-ai.withML;

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/headroom";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python
            python.pkgs.maturin
            python.pkgs.pip
            python.pkgs.virtualenv
            rustc
            cargo
            pkg-config
            openssl
            onnxruntime
          ];

          shellHook = ''
            ${python}/bin/python -m venv .venv
            source .venv/bin/activate
          '';
        };
      });
}
