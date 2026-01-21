{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "putio";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "bluesign";
    repo = "putio";
    rev = "b48bf28d2dc1e7f17140df629f3dccc50e0cb29c";
    sha256 = "sha256-0NyQG0KMY7DHWzlqxrjfDQcME7wm5r4flbCSo7byO3Q=";
  };

  vendorHash = "sha256-WvuskrBqqqIMYX0dwSArcPQO/0jl0qXFaaCzXEcvkFI=";

  doCheck = false;

  meta = with lib; {
    description = "Put.io TUI client";
    homepage = "https://github.com/bluesign/putio";
    license = licenses.mit;
    maintainers = with maintainers; [ bluesign ];
  };
}
