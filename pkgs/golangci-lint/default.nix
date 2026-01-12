{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go,
}:

buildGoModule rec {
  pname = "golangci-lint";
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "golangci";
    repo = "golangci-lint";
    rev = "v${version}";
    sha256 = "sha256-w6MAOirj8rPHYbKrW4gJeemXCS64fNtteV6IioqIQTQ=";
  };

  vendorHash = "sha256-/Vqo/yrmGh6XipELQ9NDtlMEO2a654XykmvnMs0BdrI=";

  inherit go;  # Use the same Go for building

  subPackages = [ "cmd/golangci-lint" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.commit=nixpkgs"
    "-X main.date=unknown"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Fast linters runner for Go";
    homepage = "https://golangci-lint.run/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ bluesign ];
  };
}
