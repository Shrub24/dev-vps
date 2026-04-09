{ pkgs }:
pkgs.python3.withPackages (ps: [
  (ps.beets.override {
    pluginOverrides = {
      bandcamp = {
        enable = true;
        propagatedBuildInputs = [ ps.beetcamp ];
      };
    };
  })
])
