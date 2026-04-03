{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    signing.format = null;

    includes = [
      {
        condition = "gitdir:~/repos/certifyos/";
        contents = {
          user = {
            name = "chris-certifyos";
            email = "christopher.story@certifyos.com";
          };
        };
      }
    ];

    ignores = [
      ".DS_Store"
      ".env"
      ".env.local"
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      ".vscode/"
      "node_modules/"
      "__pycache__/"
      ".direnv/"
      "*.class"
      "target/"
      ".nix-*"
    ];

    settings = {
      user = {
        name = "Christopher Story";
        email = "christory@pm.me";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        autocrlf = "input";
        pager = "delta";
      };
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        dark = true;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "base16";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        amend = "commit --amend --no-edit";
        wip = "!git add -A && git commit -m 'wip'";
      };
    };
  };
}
