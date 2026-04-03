{ pkgs, lib, username, theme, nix-vscode-extensions, ... }:

let
  # Marketplace extensions (for packages not in nixpkgs)
  marketplace = nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;

  # Shared settings for both VS Code and Cursor
  sharedSettings = {
    # ── Theme & Appearance ──────────────────────────────────────────
    "workbench.colorTheme" = theme.apps.vscode;
    "workbench.iconTheme" = "vscode-icons";

    # ── Font ────────────────────────────────────────────────────────
    "editor.fontFamily" = "'Operator Mono Lig', Menlo, Monaco, 'Courier New', monospace";
    "editor.fontSize" = 14;
    "editor.fontLigatures" = true;
    "terminal.integrated.fontFamily" = "'Operator Mono Lig', 'FiraCode Nerd Font', monospace";
    "terminal.integrated.fontSize" = 13;

    # ── Editor behavior (match nvim) ────────────────────────────────
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.wordWrap" = "off";
    "editor.cursorBlinking" = "solid";
    "editor.cursorStyle" = "block";
    "editor.lineNumbers" = "relative";
    "editor.scrolloff" = 8;
    "editor.minimap.enabled" = false;
    "editor.renderWhitespace" = "trailing";
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = true;
    "editor.formatOnSave" = true;
    "editor.linkedEditing" = true;
    "editor.indentSize" = "tabSize";

    # ── File explorer ───────────────────────────────────────────────
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;

    # ── Search ──────────────────────────────────────────────────────
    "search.smartCase" = true;

    # ── Terminal ────────────────────────────────────────────────────
    "terminal.integrated.defaultProfile.osx" = "zsh";
    "terminal.integrated.scrollback" = 5000;

    # ── Git ──────────────────────────────────────────────────────────
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.blame.editorDecoration.enabled" = true;
    "githubPullRequests.pullBranch" = "never";

    # ── Vim extension settings ──────────────────────────────────────
    "vim.enable" = true;
    "vim.leader" = "<space>";
    "vim.hlsearch" = true;
    "vim.incsearch" = true;
    "vim.ignorecase" = true;
    "vim.smartcase" = true;
    "vim.useSystemClipboard" = true;
    "vim.useCtrlKeys" = true;
    "vim.handleKeys" = {
      "<C-d>" = true;
      "<C-u>" = true;
      "<C-f>" = false;
      "<C-h>" = false;
      "<C-a>" = false;
    };
    "vim.surround" = true;

    "vim.insertModeKeyBindingsNonRecursive" = [
      { before = ["j" "k"]; after = ["<Esc>"]; }
      { before = ["j" "j"]; after = ["<Esc>"]; }
      { before = ["k" "j"]; after = ["<Esc>"]; }
      { before = ["k" "k"]; after = ["<Esc>"]; }
    ];

    "vim.normalModeKeyBindingsNonRecursive" = [
      { before = ["<leader>" "c" "h"]; commands = [":nohl"]; }
      { before = ["x"]; after = ["\"" "_" "x"]; }
      { before = ["<leader>" "s" "v"]; commands = ["workbench.action.splitEditorRight"]; }
      { before = ["<leader>" "s" "h"]; commands = ["workbench.action.splitEditorDown"]; }
      { before = ["<leader>" "s" "x"]; commands = ["workbench.action.closeActiveEditor"]; }
      { before = ["<leader>" "s" "e"]; commands = ["workbench.action.evenEditorWidths"]; }
      { before = ["<C-h>"]; commands = ["workbench.action.focusLeftGroup"]; }
      { before = ["<C-j>"]; commands = ["workbench.action.focusBelowGroup"]; }
      { before = ["<C-k>"]; commands = ["workbench.action.focusAboveGroup"]; }
      { before = ["<C-l>"]; commands = ["workbench.action.focusRightGroup"]; }
      { before = ["H"]; commands = ["workbench.action.previousEditor"]; }
      { before = ["L"]; commands = ["workbench.action.nextEditor"]; }
      { before = ["<S-q>"]; commands = ["workbench.action.closeActiveEditor"]; }
      { before = ["<leader>" "e" "e"]; commands = ["workbench.action.toggleSidebarVisibility"]; }
      { before = ["<leader>" "e" "f"]; commands = ["workbench.files.action.showActiveFileInExplorer"]; }
      { before = ["<leader>" "f" "f"]; commands = ["workbench.action.quickOpen"]; }
      { before = ["<leader>" "f" "s"]; commands = ["workbench.action.findInFiles"]; }
      { before = ["<leader>" "f" "b"]; commands = ["workbench.action.showAllEditors"]; }
      { before = ["<leader>" "c" "a"]; commands = ["editor.action.quickFix"]; }
      { before = ["<leader>" "r" "n"]; commands = ["editor.action.rename"]; }
      { before = ["<leader>" "d"]; commands = ["editor.action.showHover"]; }
      { before = ["g" "d"]; commands = ["editor.action.revealDefinition"]; }
      { before = ["g" "D"]; commands = ["editor.action.revealDeclaration"]; }
      { before = ["g" "i"]; commands = ["editor.action.goToImplementation"]; }
      { before = ["g" "t"]; commands = ["editor.action.goToTypeDefinition"]; }
      { before = ["g" "R"]; commands = ["editor.action.goToReferences"]; }
      { before = ["<leader>" "D"]; commands = ["workbench.actions.view.problems"]; }
      { before = ["<leader>" "n" "d"]; commands = ["editor.action.marker.next"]; }
      { before = ["<leader>" "p" "d"]; commands = ["editor.action.marker.prev"]; }
      { before = ["<leader>" "l" "g"]; commands = ["workbench.scm.focus"]; }
      { before = ["<leader>" "m" "p"]; commands = ["editor.action.formatDocument"]; }
      { before = ["<leader>" "T" "t"]; commands = ["testing.runAtCursor"]; }
      { before = ["<leader>" "T" "f"]; commands = ["testing.runCurrentFile"]; }
      { before = ["<leader>" "T" "s"]; commands = ["testing.runAll"]; }
      { before = ["<leader>" "T" "l"]; commands = ["testing.reRunLastRun"]; }
      { before = ["<leader>" "T" "u"]; commands = ["testing.toggleTestingPeekHistory"]; }
      { before = ["<leader>" "T" "d"]; commands = ["testing.debugAtCursor"]; }
      { before = ["<leader>" "d" "b"]; commands = ["editor.debug.action.toggleBreakpoint"]; }
      { before = ["<leader>" "d" "c"]; commands = ["workbench.action.debug.continue"]; }
      { before = ["<leader>" "d" "i"]; commands = ["workbench.action.debug.stepInto"]; }
      { before = ["<leader>" "d" "o"]; commands = ["workbench.action.debug.stepOver"]; }
      { before = ["<leader>" "d" "O"]; commands = ["workbench.action.debug.stepOut"]; }
      { before = ["<leader>" "d" "x"]; commands = ["workbench.action.debug.stop"]; }
      { before = ["<leader>" "d" "u"]; commands = ["workbench.debug.action.toggleRepl"]; }
      { before = ["<leader>" "f" "r"]; commands = ["workbench.action.replaceInFiles"]; }
    ];

    "vim.visualModeKeyBindingsNonRecursive" = [
      { before = ["<"]; commands = ["editor.action.outdentLines"]; }
      { before = [">"]; commands = ["editor.action.indentLines"]; }
      { before = ["J"]; commands = ["editor.action.moveLinesDownAction"]; }
      { before = ["K"]; commands = ["editor.action.moveLinesUpAction"]; }
      { before = ["<leader>" "m" "p"]; commands = ["editor.action.formatSelection"]; }
    ];

    # ── Formatters ──────────────────────────────────────────────────
    "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[typescriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[javascriptreact]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[html]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[yaml]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[markdown]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[svelte]"."editor.defaultFormatter" = "esbenp.prettier-vscode";

    # ── Spell check ─────────────────────────────────────────────────
    "cSpell.userWords" = [ "firestore" "healthz" ];

    # ── Spotless (Java) ─────────────────────────────────────────────
    "spotlessGradle.diagnostics.enable" = true;
    "spotlessGradle.format.enable" = true;

    # ── Misc ────────────────────────────────────────────────────────
    "vsicons.dontShowNewVersionMessage" = true;
    "quarkus.tools.alwaysShowWelcomePage" = false;
  };

  # Cursor-specific settings
  cursorSpecificSettings = {
    "go.toolsManagement.autoUpdate" = true;
  };

  sharedKeybindings = [
    { key = "ctrl+`"; command = "workbench.action.terminal.toggleTerminal"; }
  ];

  cursorKeybindings = sharedKeybindings ++ [
    { key = "ctrl+cmd+b"; command = "workbench.action.toggleAuxiliaryBar"; }
    { key = "cmd+i"; command = "composerMode.agent"; }
  ];

  cursorSettingsJson = builtins.toJSON (sharedSettings // cursorSpecificSettings);
  cursorKeybindingsJson = builtins.toJSON cursorKeybindings;

in {
  # ── VS Code (fully managed by home-manager) ───────────────────────
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;  # immutable — all extensions declared here

    profiles.default = {
      userSettings = sharedSettings;
      keybindings = sharedKeybindings;

      extensions = (with pkgs.vscode-extensions; [
        # ── Vim mode ──────────────────────────────────────────────
        vscodevim.vim

        # ── Themes (all installed, active one set by theme switcher) ─
        sdras.night-owl
        catppuccin.catppuccin-vsc          # mocha, macchiato, frappe, latte
        enkia.tokyo-night                  # night + day/light
        dracula-theme.theme-dracula
        arcticicestudio.nord-visual-studio-code
        sainnhe.gruvbox-material           # dark + light
        mvllow.rose-pine                   # moon + dawn
        github.github-vscode-theme         # dark + light

        # ── Code quality & formatting ─────────────────────────────
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        streetsidesoftware.code-spell-checker
        yoavbls.pretty-ts-errors

        # ── Languages ─────────────────────────────────────────────
        golang.go
        redhat.java
        hashicorp.terraform
        graphql.vscode-graphql
        graphql.vscode-graphql-syntax
        redhat.vscode-yaml

        # ── Java ecosystem ────────────────────────────────────────
        vscjava.vscode-gradle
        vscjava.vscode-maven
        vscjava.vscode-java-pack
        vscjava.vscode-java-dependency
        vscjava.vscode-java-debug
        vscjava.vscode-java-test

        # ── Git & collaboration ───────────────────────────────────
        github.vscode-pull-request-github
        github.vscode-github-actions

        # ── Productivity ──────────────────────────────────────────
        gruntfuggly.todo-tree
        yzhang.markdown-all-in-one
        ritwickdey.liveserver

        # ── DevOps & containers ───────────────────────────────────
        ms-vscode-remote.remote-containers
        ms-azuretools.vscode-docker
        ms-azuretools.vscode-containers
        ms-vscode.makefile-tools

        # ── Intelligence ──────────────────────────────────────────
        visualstudioexptteam.vscodeintellicode
        visualstudioexptteam.intellicode-api-usage-examples

        # ── UI ────────────────────────────────────────────────────
        vscode-icons-team.vscode-icons
      ]) ++ [
        # ── From marketplace (not in nixpkgs) ─────────────────────
        marketplace.redhat.vscode-quarkus
        marketplace.redhat.vscode-microprofile
        marketplace.atlassian.atlascode
        marketplace.nrwl.angular-console
        marketplace.orta.vscode-jest
        marketplace.wayou.vscode-todo-highlight
        marketplace.rangav.vscode-thunder-client
        marketplace.dawhite.mustache
        # Themes not in nixpkgs
        marketplace.sainnhe.everforest         # dark + light
        marketplace.qufiwefefwoyn.kanagawa
      ];
    };
  };

  # ── Cursor (config synced via file writes) ─────────────────────────
  home.file."Library/Application Support/Cursor/User/settings.json".text = cursorSettingsJson;
  home.file."Library/Application Support/Cursor/User/keybindings.json".text = cursorKeybindingsJson;
}
