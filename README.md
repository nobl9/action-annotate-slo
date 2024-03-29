# action-annotate-slo

This action applies a [Nobl9 SLO Annotation](https://docs.nobl9.com/Features/SLO_Annotations). It is useful for annotating SLOs with metadata such as release versions, maintenance or other information that can be used to correlate SLOs with other data sources or events.

## Requirements

- A valid Nobl9 account (see https://nobl9.com for more information)

## Inputs

| Parameter                | Description                                               | Required | Default                    |
|--------------------------|-----------------------------------------------------------|----------|----------------------------|
| `annotation`             | Annotation kind description                               | **Yes**  | N/A                        |
| `project`                | Project containing SLO to annotate                        | **Yes**  | N/A                        |
| `nobl9_client_id`        | The Client ID of your Nobl9 account                       | **Yes**  | N/A                        |
| `nobl9_client_secret`    | The Client Secret of your Nobl9 account                   | **Yes**  | N/A                        |
| `labels`                 | Comma separated list of labels to filter SLOs to annotate | No       | N/A                        |
| `slo`                    | Name of single SLO to annotate                            | No       | N/A                        |
| `nobl9_okta_org_url`     | Nobl9 Okta Organization URL                               | No       | https://accounts.nobl9.com |
| `nobl9_okta_auth_server` | Nobl9 Okta auth server                                    | No       | auseg9kiegWKEtJZC416       |
| `nobl9_url`              | Nobl9 API URL                                             | No       | https://app.nobl9.com/api  |
| `sloctl_version`         | `sloctl` version used by the GitHub Action                | No       | v0.0.99                    |

> When no `labels` or `slo` are provided, all SLOs in the project will be annotated.
## Example Usage

### Annotate all SLOs within a project
```yaml
name: Nobl9 Annotate SLO GitHub Actions Demo
on: [push]
jobs:
  annotate-slos:
    runs-on: ubuntu-latest
    steps:
      - uses: nobl9/action-annotate-slo@v0.1.0
        with:
          nobl9_client_id: ${{ secrets.CLIENT_ID }}
          nobl9_client_secret: ${{ secrets.CLIENT_SECRET }}
          annotation: "Release v1.0.0"
          project: "default"
```


### Annotate SLOs with labels
```yaml
name: Nobl9 Annotate SLO GitHub Actions Demo
on: [push]
jobs:
  annotate-slos:
    runs-on: ubuntu-latest
    steps:
      - uses: nobl9/action-annotate-slo@v0.1.0
        with:
          nobl9_client_id: ${{ secrets.CLIENT_ID }}
          nobl9_client_secret: ${{ secrets.CLIENT_SECRET }}
          annotation: "Release v1.0.0"
          project: "default"
          labels: "area=latency,team=orange,component=api"
```

### Annotate single SLO
```yaml
name: Nobl9 Annotate SLO GitHub Actions Demo
on: [push]
jobs:
  annotate-slos:
    runs-on: ubuntu-latest
    steps:
      - uses: nobl9/action-annotate-slo@v0.1.0
        with:
          nobl9_client_id: ${{ secrets.CLIENT_ID }}
          nobl9_client_secret: ${{ secrets.CLIENT_SECRET }}
          annotation: "Release v1.0.0"
          project: "default"
          slo: "my-slo-name"
```