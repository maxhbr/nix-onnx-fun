# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { 
          inherit system; 
          config.allowUnfree = true;
        }));
    in
    {
      devShells = forAll (pkgs:
        let
          cudaPkgs  = pkgs.cudaPackages_12_4;
          cudaLibs  = [
            "${cudaPkgs.cudatoolkit}/lib"
            "${cudaPkgs.cudnn_9_8.lib}/lib"
            "${cudaPkgs.libcublas.lib}/lib"
            "${cudaPkgs.cuda_cudart.lib}/lib"
          ];
          gccLib = "${pkgs.gcc.cc.lib}/lib";
          fetch-model = pkgs.writeShellScriptBin "fetch-model" ''
            ${pkgs.python313Packages.huggingface-hub}/bin/huggingface-cli download \
              microsoft/Phi-3-mini-4k-instruct-onnx \
              --include cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4/'*' \
              --local-dir phi
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.gcc
              cudaPkgs.cudatoolkit
              pkgs.python313
            ];

            shellHook = ''
              export LD_LIBRARY_PATH=${pkgs.lib.concatStringsSep ":" (cudaLibs ++ [ gccLib ])}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
              if [ ! -d .venv ]; then
                python3 -m venv .venv
              fi
              if [ ! -d phi ]; then
                ${fetch-model}/bin/fetch-model
              fi
              source .venv/bin/activate
              pip install --upgrade pip
              pip install --upgrade onnxruntime-genai-cuda 
            '';
          };
        });
    };
}
