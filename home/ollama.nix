{ pkgs, ... }:

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
      EnvironmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_KEEP_ALIVE = "10m";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };
  };
}
