# This is a nix-on-droid module:
# https://github.com/t184256/nix-on-droid/
{ pkgs, ... }:

{
  system.stateVersion = "20.03";
  environment.etcBackupExtension = ".backup";
  user.shell = "${pkgs.zsh}/bin/zsh";
  time.timeZone = "America/Phoenix";

  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;
    config = { pkgs, ... }: {
      imports = [
        ../home
      ];

      home.programs = with pkgs; [
        okc-agents
      ];

      programs.zsh.initExtra = ''
        # https://github.com/DDoSolitary/OkcAgent
        if type -p okc-ssh-agent > /dev/null; then
          export SSH_AUTH_SOCK=$HOME/.okc-ssh-agent
          pkill okc-ssh-agent || :
          okc-ssh-agent "$SSH_AUTH_SOCK" &
        fi
      '';
    };
  };
}
