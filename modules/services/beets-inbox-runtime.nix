{ pkgsUnstable }:
(pkgsUnstable.python3Packages.beets.override {
  pluginOverrides = {
    bandcamp = {
      enable = true;
      propagatedBuildInputs = [ pkgsUnstable.python3Packages.beetcamp ];
    };
  };
})
