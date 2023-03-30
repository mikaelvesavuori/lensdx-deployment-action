# LensDX Deployment Action

This Action informs LensDX that you have deployed your service - this helps keep your statistics up to date and in order!

Note that the LensDX Deployment Action will _not_ work without access to the Git history (i.e. `with.fetch-depth: 0`).

## Setup and usage

You need to set a required secret for an API key, then you are greenlit to just start using the action!

### Remember...

Always ensure you have secure settings regarding what actions you allow.

## Required input arguments

### `api-key`

LensDX API key.

## Environment variables the action uses

This action will use `${GITHUB_REPOSITORY}` to grab the repository name.

## An example of how to use this action in a workflow

```yml
on: [push]

jobs:
  lensdx-deployment:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          fetch-depth: 0 # We need to have access to the full Git history

      # Do your things here: build, test, deploy...

      - name: Run LensDX Deployment action
        uses: lensdx/lensdx-deployment-action@v0
        with:
          api-key: ${{ secrets.LENSDX_DEPLOYMENT_API_KEY }}
```
