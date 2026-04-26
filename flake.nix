{
  description = "Personal deployment wrapper for akutishevsky/withings-mcp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Upstream MCP server source. Keep this pinned in flake.lock and update with:
    #   nix flake lock --update-input withings-mcp-src
    withings-mcp-src = {
      url = "github:akutishevsky/withings-mcp";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      withings-mcp-src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        upstreamRevision = withings-mcp-src.rev or "unknown";
        patchedWithingsMcpSrc = pkgs.applyPatches {
          name = "withings-mcp-${upstreamRevision}-src";
          src = withings-mcp-src;
          patches = [ ./patches/withings-mcp/remove-google-analytics.patch ];
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        packages = {
          default = patchedWithingsMcpSrc;
          withings-mcp-src = patchedWithingsMcpSrc;
        };

        formatter = treefmtEval.config.build.wrapper;

        checks.formatting = treefmtEval.config.build.check self;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bun
            pkgs.nodejs_22
            pkgs.typescript
            pkgs.typescript-language-server
            pkgs.supabase-cli
            pkgs.hcloud
            pkgs.rsync
            pkgs.openssh
            pkgs.jq
            pkgs.curl
            pkgs.git
            pkgs.jujutsu
            pkgs.python3
            pkgs.nil
            pkgs.nixd
            pkgs.nixfmt
            pkgs.statix
            pkgs.deadnix
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.prettier
            treefmtEval.config.build.wrapper
          ];

          env = {
            PORT = "3000";
            LOG_LEVEL = "debug";
            WITHINGS_REDIRECT_URI = "http://localhost:3000/callback";
            HCLOUD_TOKEN = "{{HCLOUD_TOKEN}}";
          };

          shellHook = ''
            echo "withings-mcp dev shell"
            echo "upstream: akutishevsky/withings-mcp @ ${upstreamRevision}"
            echo "run: scripts/materialize-upstream"
          '';
        };
      }
    );
}
