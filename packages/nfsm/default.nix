{ lib, python3, makeWrapper, coreutils, niri }:

python3.pkgs.buildPythonApplication {
  pname = "nfsm";
  version = "0.0.2-patched";
  format = "other";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp nfsm.py $out/bin/nfsm
    chmod +x $out/bin/nfsm
    wrapProgram $out/bin/nfsm \
      --prefix PATH : ${lib.makeBinPath [ coreutils niri ]}
  '';

  meta = with lib; {
    description = "Niri FullScreen Manager - patched version with better error handling";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
