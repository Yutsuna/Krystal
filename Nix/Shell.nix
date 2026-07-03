{
  mkShell,
  crystal,
  shards,
  mold,
  krystal,
}:

mkShell {
  packages = [
    crystal
    shards
    mold
    krystal
  ];
}
