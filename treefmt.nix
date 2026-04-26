_: {
  projectRootFile = "flake.nix";

  programs.nixfmt = {
    enable = true;
    includes = [
      "*.nix"
      "nix/**/*.nix"
    ];
  };

  programs.deadnix = {
    enable = true;
    includes = [
      "*.nix"
      "nix/**/*.nix"
    ];
  };

  programs.statix = {
    enable = true;
    includes = [
      "*.nix"
      "nix/**/*.nix"
    ];
  };

  programs.shfmt = {
    enable = true;
    includes = [
      "scripts/**"
    ];
    excludes = [
      "scripts/*.example"
    ];
  };

  programs.shellcheck = {
    enable = true;
    includes = [
      "scripts/**"
    ];
    excludes = [
      "scripts/*.example"
    ];
  };

  programs.prettier = {
    enable = true;
    includes = [
      "*.md"
      "*.json"
      "deploy/**/*.json"
      "docs/**/*.md"
      "scripts/**/*.example"
    ];
  };
}
