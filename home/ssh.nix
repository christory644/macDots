{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          UseKeychain = "yes";
        };
      };
      "github.com-christory644" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/christory644";
      };
      "github.com-chris-certifyos" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/chris-certifyos";
      };
    };
  };
}
