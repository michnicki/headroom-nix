# headroom-nix

Nix flake for [headroom](https://github.com/chopratejas/headroom) — the context optimization layer for LLM applications.

## Usage

### Run directly

```sh
nix run github:michnicki/headroom-nix -- --help
```

### Add to your flake

```nix
{
  inputs = {
    headroom-nix.url = "github:michnicki/headroom-nix";
  };

  outputs = { self, nixpkgs, headroom-nix, ... }: {
    # Use the package
    environment.systemPackages = [
      headroom-nix.packages.${system}.default
    ];
  };
}
```

### Install with nix profile

```sh
nix profile install github:michnicki/headroom-nix
```

## Packages

| Attribute | Description |
|---|---|
| `headroom-ai` (default) | Standard build with magika content detection |
| `headroom-ai-ml` | Includes `transformers` for ML-based compression (pulls in PyTorch) |

```sh
nix build .#headroom-ai     # standard
nix build .#headroom-ai-ml  # with ML features
```

## Notes

- **`ast-grep-cli`** — the PyPI package bundles a platform binary; this flake uses `pkgs.ast-grep` from nixpkgs instead and injects it into PATH.
- **`sqlite-vec`** and **`magika`** — both available in nixpkgs and included by default.
- **`transformers`** — excluded from the default build due to the PyTorch dependency (~several GB). Use `headroom-ai-ml` if you need ML-based compression.
- **`ast-grep-cli`** and **`sqlite-vec`** from PyPI are removed from the dependency list and replaced by their nixpkgs equivalents.

## Dev shell

```sh
nix develop
```

Enters a shell with Python 3.12, Maturin, Rust, and the native dependencies needed to build headroom from source.
