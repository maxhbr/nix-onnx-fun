# flake.nix
{
  description = "Dev shell for running Phi-3 Mini ONNX on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; }));
    in
    {
      devShells = forAll (pkgs:
        let
          # ←–  this is the path that really contains libstdc++.so.6
          gccLibDir = "${pkgs.gcc.cc.lib}/lib";
          fetch-model = pkgs.writeShellScriptBin "fetch-model" ''
            ${pkgs.huggingface-cli}/bin/huggingface-cli download \
              microsoft/Phi-3-mini-4k-instruct-onnx \
              --include cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4/'*' \
              --local-dir phi
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.gcc                         # compiler + runtime libs
              pkgs.python313
              pkgs.python313Packages.venvShellHook
              pkgs.git
            ];

            shellHook = ''
              export LD_LIBRARY_PATH=${gccLibDir}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
              if [ ! -d .venv ]; then
                python3 -m venv .venv
              fi
              source .venv/bin/activate
              pip install --upgrade pip
            '';
          };
        });
    };
}
