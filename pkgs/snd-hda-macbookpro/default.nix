{ lib, stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation rec {
  pname = "snd-hda-codec-cs8409";
  version = "unstable-2024-06-12";

  src = fetchFromGitHub {
    owner = "egorenar";
    repo = "snd-hda-codec-cs8409";
    rev = "d8c9001418e6172099a0907f022534f152e29d71";
    hash = "sha256-uwPz2d9tJP9Tp+j0lFFKy2Dn/sVSqV2MRLec469KU+E=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
  ];

  installPhase = ''
    runHook preInstall
    install -D snd-hda-codec-cs8409.ko $out/lib/modules/${kernel.modDirVersion}/updates/snd-hda-codec-cs8409.ko
    runHook postInstall
  '';

  meta = with lib; {
    description = "Linux kernel sound driver for Cirrus Logic CS8409 (MacBooks/iMacs with Apple amplifiers)";
    homepage = "https://github.com/egorenar/snd-hda-codec-cs8409";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
