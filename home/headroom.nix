{
  config,
  lib,
  pkgs,
  ...
}:

# Headroom — context-compression proxy that sits between an AI coding agent and
# the Anthropic API, compressing tool outputs / file reads / logs / history
# before they reach the model (claimed 60-95% fewer tokens, "same answers").
# https://github.com/headroomlabs-ai/headroom  (Apache-2.0, local-first)
#
# DRAFT / PERSONAL-ONLY. This wires Headroom into the *personal* Claude config
# only (see the claude-personal alias in home/shell/zsh.nix). The work config
# (claude-work) is deliberately left untouched until this has proven itself on
# personal — a brand-new beta tool (v0.27, ~1 release/day) in the critical path
# of every agent request is exactly the thing to sandbox before letting it near
# CertifyOS code.
#
# WHY PROXY MODE (not `headroom wrap claude`): `wrap` wants to own process
# launch and invokes the real `claude` binary directly, which would bypass the
# CLAUDE_CONFIG_DIR + flags injected by the zsh alias. Proxy mode is a transparent
# localhost endpoint; the existing alias just adds ANTHROPIC_BASE_URL and composes
# cleanly with the declarative launchd-service pattern already used by ollama.nix.
#
# ── ONE-TIME MANUAL INSTALL (imperative, like `mise install`) ───────────────
# Headroom isn't in nixpkgs. Install the proxy core into an isolated venv:
#
#     python3 -m venv ~/.local/headroom-venv
#     ~/.local/headroom-venv/bin/pip install --upgrade pip
#     ~/.local/headroom-venv/bin/pip install 'headroom-ai[proxy]'
#
# Cross-agent Claude<->Codex memory (the one feature not redundant with
# Anthropic-native caching) lives behind the [memory] extra, which pulls an
# embedding runtime that may not have Python 3.14 wheels yet. Add it later once
# the proxy core is confirmed working:
#
#     ~/.local/headroom-venv/bin/pip install 'headroom-ai[memory]'
#
# ── ENABLE / DISABLE ────────────────────────────────────────────────────────
# Flip `launchd.agents.headroom.enable` below, then `rebuild`. Disabling the
# agent does NOT change the alias — remove ANTHROPIC_BASE_URL from claude-personal
# in zsh.nix to route personal Claude straight to Anthropic again.

let
  port = 8787;
  venvBin = "${config.home.homeDirectory}/.local/headroom-venv/bin/headroom";
  logDir = "${config.home.homeDirectory}/Library/Logs";

  runProxy = pkgs.writeShellScript "headroom-proxy" ''
    export PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

    if [ ! -x "${venvBin}" ]; then
      echo "[headroom] ${venvBin} not found."
      echo "[headroom] Install once with:"
      echo "[headroom]   python3 -m venv ~/.local/headroom-venv && ~/.local/headroom-venv/bin/pip install 'headroom-ai[proxy]'"
      echo "[headroom] Sleeping 5m, then this agent will retry."
      sleep 300
      exit 0
    fi

    exec "${venvBin}" proxy --port ${toString port}
  '';
in
{
  launchd.agents.headroom = {
    enable = true;
    config = {
      Label = "ai.headroomlabs.proxy";
      ProgramArguments = [ "${runProxy}" ];
      RunAtLoad = true;
      KeepAlive = true; # restart the proxy if it dies; it's in the request path
      StandardOutPath = "${logDir}/headroom-proxy.log";
      StandardErrorPath = "${logDir}/headroom-proxy.log";
      EnvironmentVariables = {
        HEADROOM_UPDATE_CHECK = "off"; # a background service shouldn't self-notify/update

        # Conservative first-run posture: input compression only. Output shaping
        # rewrites the model's *responses* and can change behavior — leave it off
        # until you trust the input path. To enable later (with a measured control
        # group instead of estimated savings), uncomment:
        # HEADROOM_OUTPUT_SHAPER = "1";
        # HEADROOM_OUTPUT_HOLDOUT = "0.1";
      };
    };
  };
}
