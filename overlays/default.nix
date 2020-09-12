# Arguments to the overlay function:
self: super:
let
  sources = import ../nix/sources.nix;
  ghc = "default";

  # Arguments to pass to derivations:
  args = {
    inherit ghc;
    pkgs = super;
  };

  # Load a package and call its function with any arguments that it
  # requests from the `args' set above.
  load = package: args:
    let
      fn = import package;
      fargs = builtins.functionArgs fn;
    in
    fn (super.lib.filterAttrs (n: _: fargs ? ${n}) args);

  # My packages have this prefix:
  prefix = "pjones/";

  # Filter out any packages that aren't mine and then load them:
  pjones = with super.lib;
    mapAttrs' (n: v: nameValuePair (removePrefix prefix n) (load v args))
      (filterAttrs (n: _: hasPrefix prefix n) sources);

  polybar-scripts = sources.polybar-scripts // {
    version = "git-" + builtins.substring 0 7 sources.polybar-scripts.rev;
  };

in
{
  pjones = pjones // {
    avatar = super.callPackage ../pkgs/pjones-avatar.nix { };
  };

  # Some local scripts:
  pulse-audio-scripts = super.callPackage ../pkgs/pulse-audio-scripts.nix { };

  # Use the version of home-manager from sources.json:
  home-manager = super.callPackage "${sources.home-manager}/home-manager" {
    path = sources.home-manager;
  };

  # Use the version of nix-on-droid from sources.json:
  nix-on-droid = super.callPackage "${sources.nix-on-droid}/nix-on-droid" { };

  # Packages that are not upstream yet:
  oreo-cursors = super.callPackage ../pkgs/oreo-cursors.nix { };

  sweet-nova = super.callPackage ../pkgs/sweet-nova.nix { };

  polybar-scripts.player-mpris-tail =
    super.callPackage ../pkgs/polybar-scripts/player-mpris-tail.nix {
      inherit polybar-scripts;
      inherit (super) stdenv;
      inherit (super.python3Packages) wrapPython dbus-python pygobject3;
    };

  # Use the latest version of Neuron:
  haskellPackages = super.haskellPackages.override (orig: {
    overrides = super.lib.composeExtensions (orig.overrides or (_: _: { }))
      (_: _: { neuron = import sources.neuron; });
  });

  # Use a more recent version of tabbed, with a patch that fixes an
  # issue with vimb:
  tabbed = super.tabbed.overrideAttrs (orig: {
    src = sources.tabbed;
    patches = (orig.patches or [ ]) ++
      [ ../pkgs/patches/tabbed-configurerequest-resize.patch ];
  });

  # Use a more recent version of vimb:
  vimb = super.wrapFirefox
    (super.vimb-unwrapped.overrideAttrs (_: {
      version = sources.vimb.branch;
      src = sources.vimb;
    }))
    { };

  # Newer version of Font-Awesome:
  font-awesome = super.font-awesome.overrideAttrs (_: {
    name = "font-awesome-" + sources.Font-Awesome.ref;
    src = sources.Font-Awesome;
  });

  # NixOps is currently broken:
  # https://github.com/NixOS/nixops/issues/1216
  nixops = (super.callPackage "${sources.nixops}/release.nix" {
    p = _: [
      (super.callPackage "${sources.nixops-libvirtd}/release.nix" { })
    ];
  }).build.${super.system};

  # Custom hooks:
  tildeInstallScripts = super.makeSetupHook
    {
      deps = [ super.makeWrapper ];
      substitutions = { shell = super.runtimeShell; };
    } ../support/setup-hooks/install-scripts.sh;

  # Various scripts needed inside tilde:
  tilde-scripts-activation = super.callPackage ../pkgs/tilde-scripts-activation.nix { };
  tilde-scripts-misc = super.callPackage ../pkgs/tilde-scripts-misc.nix { };

  tilde-scripts-lock-screen = super.callPackage ../pkgs/tilde-scripts-lock-screen.nix {
    inherit (super.xorg) xrandr xset;
    inherit (self.polybar-scripts) player-mpris-tail;
  };

  # A gpg-agent/ssh-agent for Android:
  okc-agents = super.callPackage ../pkgs/okc-agents.nix { };
}
