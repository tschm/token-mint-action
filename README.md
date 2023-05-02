# [PyPI Token Mint](https://github.com/marketplace/actions/pypi-token-mint)

[![CI](https://github.com/tschm/token-mint-action/actions/workflows/ci.yml/badge.svg)](https://github.com/tschm/token-mint-action/actions/workflows/ci.yml)

Creates an api token for trusted publishing in pypi.

## [Getting started](https://docs.pypi.org/trusted-publishers/)

"Trusted publishing" is a term for using the OpenID Connect (OIDC) standard to
exchange short-lived identity tokens between a trusted third-party service and
PyPI. This method can be used in automated environments and eliminates the need
to use username/password combinations or manually generated API tokens to
authenticate with PyPI when publishing.

For a quickstart, see:

- [Adding a trusted publisher to an existing PyPI project](https://docs.pypi.org/trusted-publishers/adding-a-publisher/)
- [Creating a PyPI project with a trusted publisher](https://docs.pypi.org/trusted-publishers/creating-a-project-through-oidc/)

### Publishing with OpenID Connect

OpenID Connect (OIDC) publishing is a mechanism for uploading packages to PyPI,
complementing existing methods (username/password combinations, API tokens).

Certain CI services (like GitHub Actions) are OIDC identity providers, meaning
that they can issue short-lived credentials ("OIDC tokens") that a third party
can strongly verify came from the CI service (as well as which user, repository,
etc. actually executed); Projects on PyPI can be configured to trust a
particular configuration on a particular CI service, making that configuration
an OIDC publisher for that project; Release automation (like GitHub Actions) can
submit an OIDC token to PyPI. The token will be matched against configurations
trusted by different projects; if any projects trust the token's configuration,
then PyPI will mint a short-lived API token for those projects and return it;
The short-lived *API token* behaves exactly like a normal project-scoped API
token, except that it's only valid for 15 minutes from time of creation (enough
time for the CI to use it to upload packages). This confers significant
usability and security advantages when compared to PyPI's traditional
authentication methods:

- Usability: With trusted publishing, users no longer need to manually create
  API tokens on PyPI and copy-paste them into their CI provider. The only manual
  step is configuring the publisher on PyPI.
- Security: PyPI's normal API tokens are long-lived, meaning that an attacker
  who compromises a package's release can use it until its legitimate user
  notices and manually revokes it. Similarly, uploading with a password means
  that an attacker can upload to any project associated with the account.
  Trusted publishing avoids both of these problems: the tokens minted expire
  automatically, and are scoped down to only the packages that they're
  authorized to upload to.

The idea of this action is to provide a mint hiding the OIDC key exchange from
the user. The user has to configure PyPI to trust the aforementioned
configuration but otherwise gets an API token which can be used to publish on
PyPI (e.g. via poetry).

### Permissions

The action assumes that it's being run in a GitHub Actions workflow runner with
the following permissions:

```yml
permissions:
  id-token: write
  contents: read
```

Those permissions are critical; without it, GitHub Actions will refuse to give
you an OIDC token.

Permissions are discussed
[here](https://github.com/glassechidna/ghaoidc/issues/1).

## Usage

### Inputs

|   Input    | Required | Default | Description |
| :--------: | :------: | :-----: | :---------- |
| `audience` | `false`  | `pypi`  | Audience    |

### Outputs

|   Output    | Description |
| :---------: | :---------- |
| `api-token` | API token   |

## Publish a Python package with Poetry

All our experiments have been performed with the
[pyhrp](https://github.com/tschm/pyhrp) package relying on
[poetry](https://python-poetry.org).

Using the new action the
[release.yml](https://github.com/tschm/pyhrp/blob/main/.github/workflows/release.yml)
file is:

```yml
name: Upload Python Package

on:
  push:
    tags:
    - '[0-9]+.[0-9]+.[0-9]'

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      # This permission is required for trusted publishing.
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python 3.10
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install Poetry
        uses: snok/install-poetry@v1.3.3
        with:
          virtualenvs-create: false

      - name: Update version (kept at 0.0.0) in pyproject.toml and build
        run: |
          poetry version ${{ github.ref_name }}
          poetry build

      - name: Mint token
        id: mint
        uses: tschm/token-mint-action@v1.0.1

      - name: Publish the package with poetry
        run: |
          poetry publish -u __token__ -p '${{ steps.mint.outputs.api-token }}'
```

## Troubleshooting

The creation of an API token rarely fails for two reasons:

- There is a mismatch between the name of the *.yml file and the trusted
  publisher configured on PyPI.
- The permissions are not set.

## Contributing

Contributions are always welcome; submit a PR!

## License

install-poetry is licensed under an Apache license. See the LICENSE file for details.
