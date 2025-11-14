Deploy.yaml -- Deploy builds to environments

Environmental deploy process:
```
  deploy-qa:
    # Needs: whatever you need to block deployment of this environment, such as a deploy-___
	# or snyk-codescan (dev only)
    needs:
      - prepare
      - deploy-dev	# Pipeline the environments
      #- snyk-codescan	# Dev-build environment
      - snyk-dockerscan	# Only really dev or the first one
	# The standard workflow file
    uses: ./.github/workflows/build-deploy.yaml
	# Copy the same deploy.yaml settings to the sub-workflows. For checking environment protection rules.
    permissions:
      id-token: write
      contents: read
    with:
	  # Parameters to build-deploy --
      deploy: yes			# Make this image active in the environment (default: no)
	  push: true			# default: true; push the image to Azure -- disable for PR test-builds
      environment: qa		# The environment for this deploy action
      gitops-repo: ecap-tech/eks-nonprod-001-manifests	# or ecap-tech/aws-eks-nonprod
      vars: ${{ toJson(vars) }}
    secrets:
	  # The secret used to push images to Azure ACR
      AZURE_ACR_SECRET: ${{ secrets.AZURE_ACR_SECRET }}
	  # The key used to clone the gitops-repo (above), a Github tokne
      DEPLOY_KEY_EKS: ${{ secrets.DEPLOY_KEY_EKS_NONPROD }}	# or DEPLOY_KEY_EKS_PROD
```

Our environment here is "qa" -- in the name of the job, and in the environment deployed to.
This job needs the prepare step (which has the "repo-name" output -- because github only offers the 
org-name/repo-name, and no way to split values in github-script), the deploy-dev step, which 
actually builds the image (BUT NOT REALLY -- if the image is not built, this step will *build* the 
image, too), and the docker scan (which requires the image already exist (-: ). Codescan is a 
dependency step for dev, so not re-stated here.
Permissions: is a block of unknown. It's defined for this deploy.yaml, by the creator of 
deploy.yaml, and its settings are passed to the reusable workflow that we're calling -- 
build-deploy.yaml.
With:
The various inputs for build-deploy. Here, we specify that we're actually deploying to the 
environment (not build-checking, not prepping a build for docker-scanning), and we need to tell it 
which repository to update with the manifest: also used DEPLOY_KEY_EKS. "vars:" is a standard 
costruct to get env vars to lower workflows -- copy-pasta.  Secrets are for just that. For non-dev 
environments, _do not_ pass in the shared-module secret, so that you can be sure a build will fail. 
Builds must happen in dev.

---
Hot Fixes

This will all be mostly the same for hot-fixes, except the branches that the deployment is run on, 
and the secrets: we'll build at a non-dev step (probably?) and allow deploy with different `needs:` 
configuration.

## The workflow permissions..

The build step is a sub-workflow, and so it can't access environment/repo/organization variables or 
secrets. Awesome! To get around this, we encode toJson(vars) andh pass it as a string-input. This 
gives *all* the root variables to the sub-workflow.

This matters for e.g. the application ID and app token for fetching Go private modules, and Snyk actions.

## Secrets and Values

AZURE_ACR_SECRET:
This secret value must be passed to each deployment step. The reason is that this step is the one
that creates environmental tags for the docker image. While these tags may not be referenced in the
deployed manifest (which only uses the git short-hash), the environmental tags are used in the
registry image-pruning script. Prod images stick around longer than dev images - so it's important
to have it tagged for each environment.

DEPLOY_KEY_EKS:
The github token used to be able to access the `manifests` repository. The manifest is updated with the
latest Docker image tag.
