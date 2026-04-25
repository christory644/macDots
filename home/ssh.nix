{ ... }:

{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";

    matchBlocks = {
      "github.com-christory644" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/christory644";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
      "github.com-chris-certifyos" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/chris-certifyos";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };
  };
}
