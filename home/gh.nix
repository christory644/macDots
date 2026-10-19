{ pkgs, ... }:

{
  # gh extensions, linked the way home-manager's programs.gh does it, without
  # enabling programs.gh: that would take over ~/.config/gh/config.yml, which
  # gh itself still writes. gh is installed system-wide in hosts/macbook.
  #
  # gh-stack (GitHub's stacked PRs) resolves the repo from the git remote and
  # does not understand ssh host aliases such as github.com-<account>; run it
  # with GH_REPO=<owner>/<repo> in those clones.
  xdg.dataFile."gh/extensions/gh-stack".source = "${pkgs.gh-stack}/bin";
}
