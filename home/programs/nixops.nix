# Settings releated to NixOps:
{ pkgs, config, lib, ... }:
let
  cfg = config.tilde.programs.nixops;

in
{
  options.tilde.programs.nixops = {
    enable = lib.mkEnableOption "nixops";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixops
    ];
  };
}
