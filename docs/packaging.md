# Packaging

The library is written for distribution as an **unlocked package**: every class that consumers
should reach is declared `global`, and `sfdx-project.json` lists `leoSFCollection` as the default
package directory.

Two things stand between the current state and a published version, and both need a decision from
the maintainer, so they are deliberately left unfilled:

## 1. Namespace

`sfdx-project.json` currently declares `"namespace": ""`. Publishing under a namespace is what
prevents collisions with a consumer's own `Collection`, `FilterByCondition`, etc. in their org.

Decide the namespace **before** the first version is created — changing it later means a new
package with a new set of installed subscribers. Once set, consumer code refers to
`yourns.Collection.of(...)`.

## 2. Package identity

Add the package name and version to the default `packageDirectories` entry and an alias map:

```json
{
  "packageDirectories": [
    {
      "path": "leoSFCollection",
      "default": true,
      "package": "LeoSCollection",
      "versionName": "LeoSCollection 1.0.0",
      "versionNumber": "1.0.0.NEXT"
    },
    { "path": "examples", "default": false }
  ],
  "namespace": "",
  "packageAliases": {
    "LeoSCollection": "0Ho..."
  }
}
```

## Coverage

Unlocked package versions require **75% Apex coverage**. The test classes in
`leoSFCollection/tests` exist to carry that:

```
sf apex run test --test-level RunLocalTests --wait 10 --result-format human --code-coverage
```

`examples/` is a separate, non-default package directory. Keep example classes (and any test that
only exercises them) out of the packaged directory, or they count toward the coverage numerator
without belonging to the shipped surface.

## Release flow

```
sf package create --name LeoSCollection --package-type Unlocked --path leoSFCollection
sf package version create --package LeoSCollection --installation-key-bypass --wait 10
sf package version promote --package LeoSCollection@1.0.0-1
sf package install --package LeoSCollection@1.0.0-1 --target-org <alias> --wait 10
```

## Do not add package.xml

`package.xml` is a Metadata API manifest for metadata-format deploys. This repository is source
format, deploy it with `sf project deploy start`; the file is already listed in `.forceignore`.
