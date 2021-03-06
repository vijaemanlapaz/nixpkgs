{pkgs, pkgs_i686}:

rec {
  platformTools = import ./platform-tools.nix {
    inherit (pkgs) stdenv fetchurl unzip;
    inherit (pkgs_i686) zlib ncurses;
    stdenv_32bit = pkgs_i686.stdenv;
  };
  
  support = import ./support.nix {
    inherit (pkgs) stdenv fetchurl unzip;
  };
  
  platforms = if (pkgs.stdenv.system == "i686-linux" || pkgs.stdenv.system == "x86_64-linux")
    then import ./platforms-linux.nix {
      inherit (pkgs) stdenv fetchurl unzip;
    }
    else if pkgs.stdenv.system == "x86_64-darwin"
    then import ./platforms-macosx.nix {
      inherit (pkgs) stdenv fetchurl unzip;
    }
    else throw "Platform: ${pkgs.stdenv.system} not supported!";

  sysimages = import ./sysimages.nix {
    inherit (pkgs) stdenv fetchurl unzip;
  };

  addons = import ./addons.nix {
    inherit (pkgs) stdenv fetchurl unzip;
  };

  androidsdk = import ./androidsdk.nix {
    inherit (pkgs) stdenv fetchurl unzip makeWrapper;
    inherit (pkgs) freetype fontconfig gtk atk;
    inherit (pkgs.xorg) libX11 libXext libXrender;
    
    inherit platformTools support platforms sysimages addons;
    
    stdenv_32bit = pkgs_i686.stdenv;
    zlib_32bit = pkgs_i686.zlib;
    libX11_32bit = pkgs_i686.xorg.libX11;
    libxcb_32bit = pkgs_i686.xorg.libxcb;
    libXau_32bit = pkgs_i686.xorg.libXau;
    libXdmcp_32bit = pkgs_i686.xorg.libXdmcp;
    libXext_32bit = pkgs_i686.xorg.libXext;
  };
  
  androidsdk_4_1 = androidsdk {
    platformVersions = [ "16" ];
    useGoogleAPIs = true;
  };
  
  buildApp = import ./build-app.nix {
    inherit (pkgs) stdenv jdk ant;
    inherit androidsdk;
  };
  
  emulateApp = import ./emulate-app.nix {
    inherit (pkgs) stdenv;
    inherit androidsdk;
  };
}
