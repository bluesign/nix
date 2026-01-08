{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "flow-cli";
  version = "2.13.3";

  src = fetchFromGitHub {
    owner = "onflow";
    repo = finalAttrs.pname;
    tag = "v${finalAttrs.version}";
    hash = "sha256-WfskYXhqNVRK7D7fyqN9S7iNNuO6H8mnMlnklYJQOQg=";
  };

  vendorHash = "sha256-ti2OaDzMAFn+qC49omNAaC9r/tni5+sfUHHOvhw9X6U=";

  ldflags = [
    "-s"
    "-w"
  ];

  doInstallCheck = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "flow-cli";
    homepage = "https://github.com/onflow/flow-cli";
    changelog = "https://github.com/onflow/flow-cli/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ onflow ];
    mainProgram = "flow-cli";
  };
})

