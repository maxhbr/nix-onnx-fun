# Step 0: launch an environment providing gcc libs

```
$ nix flake develop
```

# Step 1: fetch the model

```
$ huggingface-cli download microsoft/Phi-3-mini-4k-instruct-onnx \
  --include cpu_and_mobile/cpu-int4-rtn-block-32-acc-level-4/* \
  --local-dir cpu_and_mobile
```

# Step 2: run the LLM

## Step 2.a: on CPU:

## Step 2.b: on GPU with CUDA: