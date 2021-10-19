{
  description = "The Metaplex JS packages as a Nix Flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.npmlock2nixSrc.url = "github:cidem/npmlock2nix/fallback-char";
  inputs.npmlock2nixSrc.flake = false;
  inputs.metaplex.url = "github:metaplex-foundation/metaplex";
  inputs.metaplex.flake = false;

  outputs = { self, nixpkgs, flake-utils, npmlock2nixSrc, metaplex }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (self: super: {
              npmlock2nix = pkgs.callPackage npmlock2nixSrc { };
            })
          ];
        };

        meta = with pkgs.stdenv; with pkgs.lib; {
          homepage = "https://metaplex.com/";
          description = "Launch NFTs from your own branded storefront";
          platforms = platforms.unix ++ platforms.darwin;
        };

        fairLaunch = pkgs.npmlock2nix.build {
          meta = meta // {
            # Needs https://github.com/torusresearch/eccrypto/pull/14 for M1
            platforms = [ "x86_64-linux" "x86_64-darwin" ];
          };
          node_modules_attrs = {
            packageLockJson = ./js/packages/fair-launch/package-lock.json;
            buildInputs = with pkgs; [
              pkg-config
              python
              nodePackages.node-gyp
              nodePackages.node-gyp-build
            ] ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.CoreServices
            ]);
          };
          installPhase = ''
            mkdir $out
            cp -r node_modules $out/
            cp -r build/* $out
          '';
          buildCommands = [ "npm run build" ];
          src = "${metaplex}/js/packages/fair-launch";
        };

        # https://github.com/nix-community/npmlock2nix/issues/98 The workaround
        # in scripts/make_lockfiles for the @oyster/common dep doesn't work
        # because npmlock2nix doesn't understand it.
        web = pkgs.npmlock2nix.build {
          meta = meta // { broken = true; };
          node_modules_attrs = {
            packageLockJson = ./js/packages/web/package-lock.json;
          };
          installPhase = ''
            mkdir $out
            cp -r node_modules $out/
            cp -r build/* $out
          '';
          buildCommands = [ "npm run build" ];
          src = "${metaplex}/js/packages/web";
        };

        cli = pkgs.npmlock2nix.build
          {
            inherit meta;
            node_modules_attrs = {
              packageLockJson = ./js/packages/cli/package-lock.json;
              buildInputs = with pkgs; [
                pkg-config
                python
                nodePackages.node-gyp
                nodePackages.node-gyp-build
                pixman
                libpng
                giflib
                librsvg
                cairo
                pango
              ] ++ (with pkgs.darwin.apple_sdk.frameworks; pkgs.lib.optionals pkgs.stdenv.isDarwin [
                pkgs.darwin.cctools
                CoreText
              ]);
            };
            src = "${metaplex}/js/packages/cli";
            installPhase = ''
              mkdir $out
              cp -r node_modules $out/
              cp -r build/* $out
            '';
            buildCommands = [ "npm run build" ];
          };

      in
      rec {
        packages = flake-utils.lib.flattenTree {
          metaplex-cli = cli;
          metaplex-fair-launch = fairLaunch;
          metaplex-web = web;
        };
        defaultPackage = packages.metaplex-cli;
        apps.metaplex-cli = flake-utils.lib.mkApp { drv = packages.metaplex-cli; };
        defaultApp = apps.metaplex-cli;
        devShell = pkgs.mkShell {
          metaplex_src = metaplex;
          buildInputs = with pkgs; [
            nodejs
            fish
            jq
            moreutils
          ];
        };
      }
    );
}
