{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # `settings`, not `matchBlocks`: home-manager deprecated matchBlocks and
    # its per-host `extraOptions`, and wants upstream OpenSSH directive names
    # (HostName, IdentityFile, …) rather than the old camelCase aliases.
    #
    # Host * stays last. ssh_config takes the FIRST value it finds for any
    # given directive, so a `Host *` block placed above the specific ones
    # would win for anything they share.
    settings = {
      "github.com-christory644" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/christory644";
        IdentitiesOnly = true;
      };
      "github.com-chris-certifyos" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/chris-certifyos";
        IdentitiesOnly = true;
      };
      "*" = {
        AddKeysToAgent = "yes";
        # Was `extraOptions.UseKeychain` — macOS-only, and the reason the
        # key passphrases unlock from the login keychain without prompting.
        UseKeychain = "yes";
      };
    };
  };
}
