{ pkgs, hostname, ... }:

let
  # Ollama tuning — single source of truth for both the launchd server and
  # interactive shells (home.sessionVariables). Per-host because the two
  # machines differ ~14x in unified memory.
  perHost =
    if hostname == "christoryCertifyOSMacbook" then {
      # 256GB unified memory: full-precision KV cache, real parallelism.
      OLLAMA_KV_CACHE_TYPE = "f16";
      OLLAMA_KEEP_ALIVE = "1h";       # RAM is plentiful — keep models hot
      OLLAMA_NUM_PARALLEL = "4";
      OLLAMA_MAX_LOADED_MODELS = "3";
    } else {
      # M3 18GB: RAM limited.
      OLLAMA_KV_CACHE_TYPE = "q8_0";  # halves KV cache memory
      OLLAMA_KEEP_ALIVE = "10m";      # shorter keepalive to free RAM faster
      OLLAMA_NUM_PARALLEL = "1";      # single request at a time
      OLLAMA_MAX_LOADED_MODELS = "1"; # only one model loaded at a time
    };

  ollamaEnv = {
    OLLAMA_USE_MLX = "1";         # Apple MLX backend (unified memory, no CPU/GPU copy overhead)
    OLLAMA_FLASH_ATTENTION = "1"; # faster inference on Apple Silicon
  } // perHost;
in
{
  # Ollama — auto-start as a launchd user agent
  launchd.agents.ollama = {
    enable = true;
    config = {
      Label = "org.ollama.server";
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.err";
      EnvironmentVariables = ollamaEnv;
    };
  };

  # Same values for a manually-run `ollama serve` in a shell.
  home.sessionVariables = ollamaEnv;
}
