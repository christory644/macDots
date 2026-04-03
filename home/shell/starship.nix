{ theme, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = builtins.concatStringsSep "" [
        "[](dark_background)"
        "$os"
        "[](bg:background fg:dark_background)"
        "$username"
        "$hostname"
        "$localip"
        "[](bg:second_background fg:background)"
        "$directory"
        "[](bg:third_background fg:second_background)"
        "$git_branch"
        "$git_status"
        "[](bg:fourth_background fg:third_background)"
        "$fill"
        "$cmd_duration"
        "\${docker_context}(bg:fourth_background)"
        "\${kubernetes}(bg:fourth_background)"
        "\${helm}(bg:fourth_background)"
        "[](bg:fourth_background fg:third_background)"
        "\${terraform}(bg:third_background)"
        "\${package}(bg:third_background)"
        "\${aws}(bg:third_background)"
        "\${gcloud}(bg:third_background)"
        "\${openstack}(bg:third_background)"
        "\${azure}(bg:third_background)"
        "[](bg:third_background fg:second_background)"
        "[$all](bg:second_background)"
        "[](bg:second_background fg:background)"
        "$time"
        "[](bg:background fg:dark_background)"
        "$battery"
        "[](dark_background)"
        "$line_break"
        "$character"
      ];

      palette = theme.slug;
      command_timeout = 1000;

      palettes.${theme.slug} = theme.starship;

      os = {
        disabled = false;
        style = "bg:dark_background fg:foreground";
        format = "[$symbol ]($style)";
      };

      os.symbols = {
        Windows = "󰍲";
        Ubuntu = "󰕈";
        SUSE = "";
        Raspbian = "󰐿";
        Mint = "󰣭";
        Macos = "󰀵";
        Manjaro = "";
        Linux = "󰌽";
        Gentoo = "󰣨";
        Fedora = "󰣛";
        Alpine = "";
        Amazon = "";
        Android = "";
        Arch = "󰣇";
        Artix = "󰣇";
        EndeavourOS = "";
        CentOS = "";
        Debian = "󰣚";
        Redhat = "󱄛";
        RedHatEnterprise = "󱄛";
      };

      username = {
        show_always = true;
        style_user = "bg:background fg:purple";
        style_root = "bg:background fg:red";
        format = "[$user ]($style)";
      };

      hostname = {
        ssh_only = true;
        ssh_symbol = " ";
        style = "bold dimmed bg:background fg:yellow";
        format = "[$ssh_symbol$hostname]($style)";
        disabled = false;
        trim_at = "";
      };

      localip = {
        ssh_only = true;
        style = "bold dimmed bg:background fg:red";
        format = "@[$localipv4]($style)";
        disabled = false;
      };

      directory = {
        style = "bg:second_background fg:blue";
        format = "[ $path ]($style)$read_only";
        truncate_to_repo = false;
      };

      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = "󰝚 ";
        "Pictures" = " ";
        "repos" = "󰲋 ";
      };

      git_branch = {
        symbol = "";
        style = "bg:third_background";
        format = "[[ $symbol $branch ](fg:yellow bg:third_background)]($style)";
      };

      git_status = {
        conflicted = "[󰦦\\($count\\)](bg:third_background fg:error_red)";
        ahead = "[\${count}](bg:third_background fg:green)";
        behind = "[\${count}](bg:third_background fg:green)";
        diverged = "[[󰹹](bg:third_background fg:error_red) [\${ahead_count}](bg:third_background fg:green) [\${behind_count}](bg:third_background fg:error_red)](bg:third_background)";
        up_to_date = "[✓](bg:third_background fg:yellow)";
        format = builtins.concatStringsSep "" [
          "$conflicted"
          "[$deleted$renamed$modified$untracked](bg:third_background fg:error_red)"
          "[$staged](bg:third_background fg:green)"
          "[$stashed](bg:third_background fg:error_red)"
          "$ahead_behind"
        ];
      };

      fill = {
        symbol = " ";
        style = "bg:fourth_background fg:foreground";
      };

      cmd_duration = {
        min_time = 500;
        show_milliseconds = false;
        style = "bold dimmed bg:fourth_background fg:orange";
        disabled = false;
        format = "[took $duration]($style)";
      };

      time = {
        disabled = false;
        use_12hr = true;
        format = "[  $time]($style)";
        style = "bg:background fg:purple";
      };

      battery = {
        disabled = false;
        format = "[ $symbol](bg:dark_background fg:foreground)[$percentage]($style)";
        display = [
          { threshold = 10; style = "bg:dark_background fg:bold error_red"; }
          { threshold = 20; style = "bg:dark_background fg:red"; }
          { threshold = 100; style = "bg:dark_background fg:green"; }
        ];
      };

      character = {
        disabled = false;
        success_symbol = "[󰧛](bold fg:cyan)";
        vimcmd_symbol = "[󰧙](bold fg:orange)";
        vimcmd_replace_one_symbol = "[󰧙](bold fg:purple)";
        vimcmd_replace_symbol = "[󰧙](bold fg:purple)";
        vimcmd_visual_symbol = "[󰧝](bold fg:cyan)";
      };

      # Language modules
      nodejs = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version [$engines_version](fg:error_red bg:second_background))](fg:blue bg:second_background)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version [$mod_version](fg:error_red bg:second_background))](fg:blue bg:second_background)]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      python = {
        pyenv_version_name = true;
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      elixir = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version \\(OTP $otp_version\\) ) ](fg:blue bg:second_background)]($style)";
      };

      lua = {
        symbol = "";
        style = "bg:second_background";
        format = "[[ $symbol( $version) ](fg:blue bg:second_background)]($style)";
      };

      # Infrastructure modules
      docker_context = {
        symbol = "";
        style = "bg:fourth_background";
        format = "[[ $symbol( $context) ](fg:blue bg:fourth_background)]($style)";
      };

      helm = {
        style = "bg:fourth_background";
        format = "[[ $symbol( $version) ](fg:blue bg:fourth_background)]($style)";
      };

      kubernetes = {
        symbol = "󱃾";
        style = "bg:fourth_background";
        format = "[[ $symbol( $context \\($namespace\\)) ](fg:blue bg:fourth_background)]($style)";
        disabled = false;
      };

      terraform = {
        symbol = "󱁢";
        style = "bg:third_background";
        format = "[[ $symbol$version( $workspace) ](fg:yellow bg:third_background)]($style)";
      };

      package = {
        symbol = "";
        style = "bg:third_background";
        format = "[[ $symbol( $version) ](fg:yellow bg:third_background)]($style)";
      };

      aws = {
        symbol = "";
        style = "bg:third_background";
        format = "[[ $symbol $region( $profile) ](fg:yellow bg:third_background)]($style)";
      };

      gcloud = {
        symbol = "";
        style = "bg:third_background";
        format = "[[ $symbol$account ](fg:yellow bg:third_background)]($style)";
      };

      openstack = {
        style = "bg:third_background";
        format = "[[ $symbol$cloud( $project) ](fg:yellow bg:third_background)]($style)";
      };

      azure = {
        symbol = "";
        style = "bg:third_background";
        format = "[[ $symbol( $username) ](fg:yellow bg:third_background)]($style)";
        disabled = false;
      };
    };
  };
}
