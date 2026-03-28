{ lib, ... }:
let
  # Canonical break-glass/operator key source for oci-melb-1.
  # Keep recovery keys declared in Nix; do not rely on OCI metadata.
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCcCrrwmxabl1/fnYTkrlMLa+I4ucauph3GMtTvDg4B/EyzsEFUB+sOEf9sLpdnocsxOaUu4e6qE2sZRWJHafIo8gidE3JB/Ogf9aeddWjukeYH3EddJDd0iPqCL2JMPdVpNi/Ly/RAcxi2ENSZf5eoX30EEkC3s2kzxJ1znlhS6YOjG1XFdmjtf5bMnj4JFxXNhEa5mpzR6G5Qua2lcaA53+J20mldyRGYSrQAnR2E0x0k0XS95/jJ7xo7pCqPyCkT2zBTzRoEb1A+4ulHsuW9d6nk6W61nUX3QDj4gNGcq9jUmtHVd+OdZPKU1ILWWHm8x2YDPron3wihe072VWEhwG8ojmfqeKUceF41/ymN1ws9DhxNaF+ofJwuGR8J9afPXeYfV1qxOvpSwKHvLCNsPP88HApd+0q5JADeclUGtrnfNxNolnTowA6dFJ1tqXE7doYiyaoitnHmR8DO/k0SQ21wnScfJUSdkD/Ifcz8M+36qB2/SkdUG788hpIObs0= saurabhj@Saurabh-fedora"
  ];
in
{
  users.mutableUsers = false;

  assertions = [
    {
      assertion = sshKeys != [ ];
      message = "oci-melb-1 requires at least one declarative SSH recovery key";
    }
  ];

  users.users.dev = {
    isNormalUser = true;
    description = "Dev User";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = sshKeys;
}
