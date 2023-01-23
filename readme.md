
<div align="center">
<img src="https://github.com/gbrls/cabueta/raw/main/images/cabueta.svg" width=200/>
</div>

Cabueta is a DevSecOps Security Scan tool made for Github. It performs Static analysis, Dependency scanning,
Dynamic analysis, and Secrets scanning. It integrates with your project via
Github Actions.

Cabueta was created to improve Security at [VTEX](https://vtex.com/us-en/). It solves the issue of Insecure CI/CD pipelines, integrating security directly with CI/CD. It provides clear and actionable output via Markdown, and the JSON output for each tool.


<div align="center">
<img src="https://github.com/gbrls/cabueta/raw/main/images/report.jpg" width=700/>

_Sample report generated by cabueta._
</div>


## Tools & Features

- Secrets Scanning with [Gitleaks](https://github.com/zricethezav/gitleaks)
- Dependency Scanning with [osv-scanner](https://github.com/google/osv-scanner)
- Static Code Analysis with [Semgrep](https://github.com/returntocorp/semgrep)
- Dynamic Application Security Testing with [Nuclei](https://github.com/projectdiscovery/nuclei)


- **Access resources in the AWS using OpenID Connect**. With Identity Federation it's possible to access resources in AWS from the Github Actions runner. One possible application is that for all repositories under an organization will send logs **securely** via POST to an AWS Lambda function, those POST requests will be authenticated by Github and AWS. More info [here](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)



## Usage

To use cabueta as an **Workflow**:

```yaml
name: cabueta
on:
  # Other options can be added here to make cabueta run on a per PR and per commit basis
  workflow_dispatch:

jobs:
  cabueta:
    uses: gbrls/cabueta/.github/workflows/cabueta.yml@main
    with:
      # Turn this on if you want nuclei to test the target-url
      dast-check: false
      target-url: https://your-website-here.com
      
      # Configure and turn this on if you want to collect logs in your endpoint
      upload-logs: false
      aws-role: AWS_ROLE_HERE
      aws-region: AWS_REGION_HERE
      upload-url: https://endpoint-to-collect-logs-via-http-post.com

  print:
    runs-on: ubuntu-latest
    needs: cabueta
    steps:
    - name: Print output
      run: echo ${{ needs.cabueta.outputs.report }}
```


## VTEX Winter Internship 2022

<img src="https://github.com/gbrls/cabueta/raw/main/images/vtex-logo.png" width=150/>


This tool was the project of my Internship Program at
[VTEX](https://vtex.com/us-en/).


