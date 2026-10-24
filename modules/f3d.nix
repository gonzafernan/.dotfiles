{ pkgsUnstable, ... }:

let
  mesa = pkgsUnstable.mesa;
  # f3d renders through GLX, which can't find a Mesa driver on non-NixOS without this;
  # the session's 24.11 Mesa doesn't match unstable's libglvnd.
  f3d = pkgsUnstable.symlinkJoin {
    name = "f3d";
    paths = [ pkgsUnstable.f3d ];
    nativeBuildInputs = [ pkgsUnstable.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/f3d \
        --prefix LD_LIBRARY_PATH : ${mesa}/lib \
        --set LIBGL_DRIVERS_PATH ${mesa}/lib/dri \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesa}/share/glvnd/egl_vendor.d/50_mesa.json
    '';
  };
in
{
  home.packages = [ f3d ];

  xdg.configFile."f3d/config.json".source = ../config/f3d/config.json;

  # Store path: yazi launched from Hyprland doesn't have the Nix profile on PATH.
  xdg.configFile."yazi/yazi.toml".text = ''
    [opener]
    f3d = [{ run = '${f3d}/bin/f3d %s', orphan = true, desc = "F3D" }]

    [open]
    prepend_rules = [{ url = "*.{stl,STL,step,STEP,stp,STP,iges,IGES,igs,IGS,3mf,obj,glb,gltf,ply}", use = "f3d" }]
  '';
}
