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
            ${pkgs.python313Packages.huggingface-hub}/bin/huggingface-cli download microsoft/phi-4-onnx --include cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4/'*' --local-dir phi4
            ${pkgs.python313Packages.huggingface-hub}/bin/huggingface-cli download microsoft/phi-4-onnx --include gpu/* --local-dir phi4
          '';
          run-model-cpu = pkgs.writeShellScriptBin "run-model-cpu" ''
            set -x
            python phi3-qa.py -m phi4/cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4 -e cpu
          '';
          run-model-cuda = pkgs.writeShellScriptBin "run-model-cuda" ''
            set -x
            python phi3-qa.py -m phi4/gpu/gpu-int4-rtn-block-32 -e cuda
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
              if [ ! -d phi4 ]; then
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
