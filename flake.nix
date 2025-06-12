# flake.nix
{
  description = "Dev shell for running Phi-3 Mini ONNX on NixOS";
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
          cudaPkgs  = pkgs.cudaPackages_12_4;     # change to _12_3, _11_8 … if needed
          cudaLibs  = [
            "${cudaPkgs.cudatoolkit}/lib"
            "${cudaPkgs.cudnn}/lib"
            "${cudaPkgs.libcublas}/lib"
            "${cudaPkgs.cuda_cudart}/lib"
          ];
          gccLibDir = "${pkgs.gcc.cc.lib}/lib";
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
              pkgs.gcc                         # compiler + runtime libs
              cudaPkgs.cudatoolkit
              cudaPkgs.cudnn_9_8
              cudaPkgs.libcublas
              cudaPkgs.cuda_cudart
              pkgs.python313
              pkgs.python313Packages.venvShellHook
              pkgs.git
            ];

            shellHook = ''
              export LD_LIBRARY_PATH=${pkgs.lib.concatStringsSep ":" (cudaLibs ++ [ gccLibDir ])}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
              if [ ! -d .venv ]; then
                python3 -m venv .venv
              fi
              if [ ! -d phi ]; then
                ${fetch-model}/bin/fetch-model
              fi
              source .venv/bin/activate
              pip install --upgrade pip
            '';
          };
        });
    };
}
