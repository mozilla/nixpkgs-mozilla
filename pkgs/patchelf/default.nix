{ stdenv, patchelf, makeWrapper }:
let 
  patchelf' = patchelf.overrideAttrs(old: {
    patches = old.patches or [] ++ [ ./no-clobber-old-sections.patch ]; 
  });
in stdenv.mkDerivation {
  pname = "patchelf-wrapped";
  inherit (patchelf) version;

  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${patchelf'}/bin/patchelf $out/bin/patchelf --add-flags "--no-clobber-old-sections"
  '';
}
