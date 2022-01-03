# Archived

Maintaining JS and TS projects in Nix is a nightmare. Due to the large number of dependencies,
something is always broken. And then someone adds a weird postinstall script, which has no hope
of ever succeeding in Nix.

Additionally, I myself don't use any of these packages so there's little value for me in
maintaining any of this.

# Metaplex Nix

This repository bundles the Metaplex JS CLI tools in the form of a Nix flake.
It checks out a given commit of the upstream repository, generates missing
`package-lock.json` files and then it uses `npmlock2nix` to turn the packages
into Nix derivations.

Check the ouputs with `nix flake show github:cidem/metaplex-js-nix-flake`

Packages that don't work on certain platforms are marked as broken. Right now
`web` can't be used at all, because I haven't figured out how to work around
Lerna.

`fair-launch` can't be used on Darwin M1 because a transitive dependency is
missing `aarch64` as a target architecture for GYP bindings.

The typical use case is:

```shell
$ nix build github:cidem/metaplex-js-nix-flake

$ node ./result/candy-machine-cli.js
Usage: candy-machine-cli [options] [command]

Options:
  -V, --version                                      output the version number
  -h, --help                                         display help for command

Commands:
  upload [options] <directory>
  verify_token_metadata [options] <directory>
  verify [options]
  verify_price [options]
  show [options]
  create_candy_machine [options]
  update_candy_machine [options]
  mint_one_token [options]
  sign [options]
  sign_all [options]
  generate_art_configurations [options] <directory>
  create_generative_art [options]
  help [command]                                     display help for command
```
