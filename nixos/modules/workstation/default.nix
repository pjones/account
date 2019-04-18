{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.pjones;
  base = import ../../../pkgs { inherit pkgs; };

  # Set XDG environment variables to my liking:
  xdg-set-up = pkgs.writeScript "xdg-set-up" (readFile ../../../support/workstation/xdg.sh);

  # Reuse the startkde script from NixOS:
  xsessions = config.services.xserver.desktopManager.session.list;
  startkde = (head (filter (d: d.name == "plasma5") xsessions)).start;
in
{
  # Additional files:
  imports = [
    ./gromit-mpx.nix
    ./ipfs.nix
    ./keyboard.nix
    ./mail.nix
    ./mpd.nix
    ./syncthing.nix
    ./yubikey.nix
  ];

  #### Implementation:
  config = mkIf cfg.isWorkstation {

    # Make sure X is enabled:
    services.xserver.enable = mkDefault true;
    services.xserver.layout = mkDefault "us";
    services.xserver.displayManager.sddm.enable = mkDefault true;
    services.xserver.desktopManager.plasma5.enable = mkDefault true;

    # Extra groups needed on a workstation:
    users.users.pjones.extraGroups = [
      "cdrom"
      "dialout"
      "disk"
      "networkmanager"
      "scanner"
    ];

    # Some things only work if installed in the system environment:
    environment.systemPackages = with pkgs; [
      arc-icon-theme
      arc-theme
      gwenview
      hicolor_icon_theme
      kdeconnect
      playbar2
      qt5.qttools
    ] ++ filter isDerivation (attrValues pkgs.kdeApplications);

    # Extra packages:
    users.users.pjones.packages = with pkgs; [
      # Desktop
      bspwm
      calibre
      glabels
      libnotify
      libreoffice
      pamixer
      pavucontrol
      rofi
      ssvnc
      sxhkd
      x11vnc
      xclip
      xdo
      xdotool
      xorg.xev
      xorg.xhost
      xorg.xrandr
      xorg.xset
      xtitle
      zathura

      # System and Security
      aspell
      aspellDicts.en
      dict
      nixops
      pass

      # Network
      chromium
      firefox
      mu
      youtube-dl

      # Audio/Video
      abcde
      atomicparsley
      beets
      bs1770gain
      cdparanoia
      cdrkit          # cdrecord, mkisofs, etc.
      ffmpeg
      handbrake
      lame
      makemkv
      moc
      mpc_cli
      mpg123
      ncmpcpp
      spotify
      vlc

      # Creative
      darktable
      geda
      gimp
      imagemagick
      inkscape
      kicad
      librecad
      ngspice
      openscad
      pdftk
      qmapshack
      slic3r
      xournal

      # Development
      haskellPackages.hlint
      libxml2
      libxslt
      mr
      nodePackages.eslint
      nodejs-slim-8_x
      shellcheck

    ] ++ (with base; [
      # My packages
      encryption-utils
      emacsrc
      vimeta
    ]);

    # Home Manager:
    home-manager.users.pjones = { ... }: {
      # Files in ~pjones:
      home.file.".emacs".source = "${base.emacsrc}/dot.emacs.el";

      # Services:
      xsession = {
        enable = true;
        windowManager.command = startkde;

        # Run before the window manager:
        initExtra = ''
          ${xdg-set-up}
          export KDEWM=${pkgs.bspwm}/bin/bspwm
        '';
      };

      # Hide the mouse.
      services.unclutter.enable = true;

      # Cache passphrases and keys:
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 3600;
        defaultCacheTtlSsh = 14400;
        maxCacheTtl = 7200;
        maxCacheTtlSsh = 21600;
      };

      # Make things pretty:
      services.compton = {
        enable = true;

        fade = true;
        fadeExclude = [
          "window_type *= 'menu'"
        ];

        inactiveOpacity = "0.85";
        opacityRule = [
          "20:class_i *= 'presel_feedback'"
          "99:class_i *= 'sddm'"
          "99:class_i  = 'rofi'"
        ];

        extraOptions = ''
          unredir-if-possible = true;
          use-ewmh-active-win = true;
        '';
      };
    };
  };
}
