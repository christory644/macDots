{ ... }:

# mise — language runtime / tool version manager. The global config used to be
# a hand-edited ~/.config/mise/config.toml; folded into nix here so it's
# reproducible (and so the Mac Studio gets the same behavior).
#
# Tools are activated in the shell via `eval "$(mise activate zsh)"` in
# home/shell/zsh.nix. Actual installs live in ~/.local/share/mise/installs and
# are imperative — run `mise install` after changing the tool list here.
#
# auto_install = false is LOAD-BEARING: with it on, every cold shell entering a
# trusted path ran `mise hook-env` in its precmd hook and synchronously compiled
# any "latest" runtime it didn't have yet (python/go/rust/…), blocking the
# prompt for minutes. After a reboot every restored terminal did this at once —
# the "hung panes". Keep installs explicit (`mise install`), never on shell startup.

{
  xdg.configFile."mise/config.toml".text = ''
    [tools]
    node = "latest"
    go = "latest"
    python = "latest"
    java = "latest"
    elixir = "latest"
    zig = "latest"
    bun = "latest"
    rust = "latest"
    php = "latest"
    maven = "latest"
    gradle = "latest"
    quarkus = "latest"

    [settings]
    auto_install = false
    trusted_config_paths = ["~/repos"]
  '';
}
