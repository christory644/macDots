{ pkgs, ... }:

# Git always talks SSH, always with one of these two keys, and the OWNER in the
# URL decides which: anything under CertifyOS is work, everything else personal.
#
# This is what the github.com-<account> ssh aliases were always for. They work
# fine when a remote actually uses one. The gap is that `gh repo clone
# CertifyOS/<repo>` hands git a PLAIN git@github.com:OWNER/REPO address — gh's
# per-host git_protocol is ssh, and gh's own tokens play no part in the clone.
# Plain github.com offers whichever key ssh-agent lists first, the personal one,
# so every work clone failed with "Please make sure you have the correct access
# rights" while `gh` itself looked perfectly healthy.
#
# It cannot be fixed in ssh_config: SSH sees only the host, never the repo path,
# so it cannot tell a CertifyOS URL from a personal one on plain github.com.
# The owner distinction only exists at the git layer. The rules below map every
# plain form onto the existing aliases, so the aliases stay the single place
# that binds a key — they just stop being something you have to remember to
# type.
#
# insteadOf picks the LONGEST matching prefix, which is what lets one mechanism
# say "work for this org, personal for everything else". Existing
# `github.com-<account>:` remotes are untouched: after "github.com" they have
# "-", not ":", so they match neither prefix and are never double-rewritten.
#
# THE TRAP, verified rather than assumed: insteadOf rewrites the TRANSPORT only.
# A clone made through it stores the ORIGINAL url in .git/config — tested
# offline against a local bare repo, which recorded the pre-rewrite form. So the
# work-identity include cannot key off the rewritten address; it has to match
# every spelling that can legitimately land in a remote, or commits silently go
# out as the personal identity.

let
  workIdentity = {
    user = {
      name = "chris-certifyos";
      email = "christopher.story@certifyos.com";
    };
  };

  # The owners that belong to the work account. Single source of truth: both
  # the url rewrites and the identity includes below are generated from it, so
  # adding an org or a repo owner is a one-line change that cannot drift.
  #
  # chris-certifyos is here alongside the org because the work USER owns repos
  # too (certifyos-auto-kanban). An owner rule written as "CertifyOS only"
  # silently routes those to the personal key.
  workOwners = [ "CertifyOS" "chris-certifyos" ];

  workAlias = "git@github.com-chris-certifyos:";
  persAlias = "git@github.com-christory644:";

  # Every spelling of a work remote that can end up written in .git/config.
  workRemotes = builtins.concatMap (o: [
    "${workAlias}${o}/**"
    "git@github.com:${o}/**"
    "https://github.com/${o}/**"
  ]) workOwners;
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    signing.format = null;

    includes = map (url: {
      condition = "hasconfig:remote.*.url:${url}";
      contents = workIdentity;
    }) workRemotes;

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
      ".mise.toml"
      ".mise.local.toml"
      "*.class"
      "target/"
      ".nix-*"
    ];

    settings = {
      # Owner decides the key. https is folded into ssh too, so git never falls
      # back to a token-based transport.
      url =
        # One rewrite per work owner, plus a catch-all onto the personal alias.
        # insteadOf takes the LONGEST matching prefix, so the owner-specific
        # rules outrank the catch-all beneath them.
        (builtins.listToAttrs (map (o: {
          name = "${workAlias}${o}/";
          value.insteadOf = [ "git@github.com:${o}/" "https://github.com/${o}/" ];
        }) workOwners))
        // {
          ${persAlias}.insteadOf = [ "git@github.com:" "https://github.com/" ];
        };

      # Default identity; the includes above override it for CertifyOS remotes.
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
