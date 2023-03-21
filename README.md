# LensDX Deployment Action

An action to informs LensDX that you have deployed your service - helps keep your statistics up to date and in order!

## Setup and usage

You need to set a required secret for an API key, then you are greenlit to just start using the action!

### Remember...

- Always ensure you have secure settings regarding what actions you allow.
- Note that LensDX will _not_ work without access to the Git history (i.e. `with.fetch-depth: 0`).

## Required input arguments

### `api-key`

LensDX API token.

## Environment variables the action uses

This action will use `${{ github.event.repository.name }}` to grab the repository name.

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
          api-key: ${{ secrets.LENSDX_DEPLOYMENT_API_KEY }} # Use whatever secret name you want!
```