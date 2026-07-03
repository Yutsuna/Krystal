{
  lib,
  crystal,
  makeWrapper,
  mold,
}:

crystal.buildCrystalPackage {
  pname = "krystal";
  version = "0.1.0";
  src = ../.;
  format = "shards";
  shardsRepo = null;
  buildTargets = [ "Source/Krystal.cr" ];

  nativeBuildInputs = [
    makeWrapper
    mold
  ];

  postInstall = ''
    wrapProgram $out/bin/krystal \
      --prefix PATH : ${
        lib.makeBinPath [
          crystal
          mold
        ]
      }
  '';
}
