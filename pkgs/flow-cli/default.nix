{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
  go,
}:


buildGoModule rec {
  name = "flow-cli";
  nativeBuildInputs = [ git go ];
  src = fetchFromGitHub {
    owner = "onflow";
    repo = "flow-cli";
    rev = "v2.13.3";
    sha256 = "sha256-WfskYXhqNVRK7D7fyqN9S7iNNuO6H8mnMlnklYJQOQg=";
  };
  vendorHash = "sha256-T5z3z0/qm+jIuS8IX9kwYMaARLAOxy+VOT/yuotcfx8=";
  #lib.fakeHash;

  proxyVendor = true;
  doCheck = false;

  meta = with lib; {
    description = "Flow CLI";
    homepage = "https://github.com/onflow/flow-cli";
    license = licenses.mit;
    maintainers = with maintainers; [bluesign];
  };
}
