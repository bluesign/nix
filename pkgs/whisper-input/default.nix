{ lib, python3, makeWrapper, wtype, whisper-cpp }:

python3.pkgs.buildPythonApplication rec {
  pname = "whisper-input";
  version = "0.2.0";

  src = ./src;

  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp whisper_input.py $out/bin/whisper-input
    chmod +x $out/bin/whisper-input
    wrapProgram $out/bin/whisper-input \
      --prefix PATH : ${lib.makeBinPath [ wtype whisper-cpp ]}
  '';

  meta = with lib; {
    description = "Voice-to-text input using whisper-stream";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
