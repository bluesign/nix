{ python3Packages, ghidra, makeWrapper, jdk21 }:

python3Packages.buildPythonPackage {
  pname = "pyghidra";
  version = "2.2.1";
  format = "wheel";

  src = "${ghidra}/lib/ghidra/Ghidra/Features/PyGhidra/pypkg/dist/pyghidra-2.2.1-py3-none-any.whl";

  nativeBuildInputs = [ makeWrapper ];

  dependencies = with python3Packages; [
    jpype1
    packaging
  ];

  pythonImportsCheck = [];
  doCheck = false;

  postFixup = ''
    wrapProgram $out/bin/pyghidra \
      --set GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra" \
      --set JAVA_HOME_OVERRIDE "${jdk21}" \
      --set JAVA_HOME "${jdk21}" \
      --prefix PATH : "${jdk21}/bin"
  '';
}
