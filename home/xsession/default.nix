{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.pjones.xsession;

  # Set XDG environment variables to my liking:
  xdg-set-up = pkgs.writeScript "xdg-set-up"
    (lib.readFile ../../support/workstation/xdg.sh);

  # Background images:
  images = pkgs.callPackage ./images.nix { };
in
{
  imports = [
    ./dunst.nix
    ./grobi.nix
    ./lock.nix
    ./polybar.nix
    ./rofi.nix
    ./theme.nix
    ./vimb.nix
    ./wallpaper.nix
  ];

  options.pjones.xsession = {
    enable = lib.mkEnableOption "Enable an X11 session";
  };

  config = lib.mkIf cfg.enable {
    # Enable other xsession modules:
    pjones.programs.oled-display.enable = lib.mkDefault true;
    pjones.xsession.dunst.enable = lib.mkDefault true;
    pjones.xsession.grobi.enable = lib.mkDefault true;
    pjones.xsession.polybar.enable = lib.mkDefault true;
    pjones.xsession.rofi.enable = lib.mkDefault true;
    pjones.xsession.theme.enable = lib.mkDefault true;
    pjones.xsession.vimb.enable = lib.mkDefault true;
    pjones.xsession.wallpaper.enable = lib.mkDefault true;

    # Enabling an xsession also enables workstation settings:
    pjones.workstation.enable = true;

    xsession = {
      enable = true;
      windowManager.command = ''
        ${xdg-set-up}

        # Set initial background image:
        ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${images.login}

        # Launch my window manager:
        ${pkgs.pjones.xmonadrc}/bin/xmonadrc
      '';
    };

    # Services to start when running X11:
    services.udiskie.enable = true;
    services.unclutter.enable = true;

    # Nix drv caching and background building:
    services.lorri.enable = true;

    # Communicate with my phone:
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };

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
    services.picom = {
      enable = true;
      blur = true;
      fade = true;
      shadow = true;
      shadowExclude = [ "focused = 0" ];

      extraOptions = ''
        shadow-red   = 0;
        shadow-green = 0.91;
        shadow-blue  = 0.78;
        xinerama-shadow-crop = true;
      '';
    };

    # Extra programs to install:
    home.packages = with pkgs; [
      # Desktop
      calibre
      glabels
      kdeApplications.spectacle
      libnotify
      libreoffice
      pamixer
      pavucontrol
      tabbed
      wmctrl
      x11vnc
      xclip
      xdo
      xdotool
      xorg.xev
      xorg.xhost
      xorg.xrandr
      xorg.xset
      xorg.xwininfo
      xtitle

      # Network
      chromium
      firefox

      # Audio/Video
      cantata
      cdparanoia
      handbrake
      makemkv
      spotify
      vlc

      # Creative
      gwenview
      darktable
      gimp
      imagemagick
      inkscape
      kicad
      librecad
      ngspice
      openscad
      prusa-slicer
      qmapshack
      slic3r
      xournal
    ];
  };
}
