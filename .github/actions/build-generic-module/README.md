# build-generic-module

## Arguments for the build phase
* `image-name`
  * The name of the result image. Only the name. In container registries, it is called repository name.
  * **Required**
* `target-env`
  * Valid values are `dev`, `qa`, `uat`, `load`, `stg` and `prod`. Can be either a single name or a comma-separated list of names.
    Note: stg and prod must not be mixed with other environments. stg and prod must not be deployed at the same time.
  * **Required**
* `azure-acr-secret`
  * Just put it like this `${{ secrets.AZURE_ACR_SECRET }}`. That secret is defined at the organization level and 
        available to all repositories. If this input is not provided, the action will look for the secret in the 
        environment variable name `AZURE_ACR_SECRET`. So if your repository has many modules to build, to save a line
        at every build step, just define the env var `AZURE_ACR_SECRET` at the workflow `env:`

### Either build with Dockerfile
If argument `bake-files` is given, all arguments of this group will be ignored.

* `dockerfile`
  * The path to the Dockerfile
  * Default: `Dockerfile` The file must be placed at the root of your source code repo 
* `build-secrets`
  * Docker build secrets, the string in the format like this: `KEY_1=value1 KEY_1=value2`
  * Optional
* `build-args`
  * Docker build arguments, the string in the format like this: `KEY_1=value1 KEY_1=value2`
  * Optional
  
* `build-context`
  * Docker build context
  * default: "." The root of your source code repo.

* `build-contexts-additional`
  * List of additional build contexts to pass to the docker/build-and-push. 
        Format: `contextName1==path/to/the/folder1 contextName2==path/to/the/folder2`
  * Optional

### Or Docker bake
* `bake-files`
  * comma-separated list of bake files. When this input is specified, all the Dokerfile-related arguments described above won't be used
* `bake-targets`
  * Only used when `bake-files` is given. Comma-separated list of targets to build at the same time
  * Default value is `default`

## Arguments for the deployment phase
* `deploy`
  * yes/no. If yes the action will update the gitops repo, consequently, trigger the deployment. If no, all following arguments won't be used
  * Default: no
* `app-name`
  * A short business friendly name, just to construct the commit message to gitops repo.
  * If this is not provided and `gitops-app-name` is provided, `gitops-app-name` will be used.
    Both `app-name` and `gitops-app-name`, in that case, `app-name` will be used to build the gitops commit message,
    i.e. `app-name` can be an abbreviation.
* `gitops-app-name`
  If provided and
     * If `app-name` is not provided, this is used for `app-name`.
      - If `gitops-overlay-folder` is not provided, the folder will be: `apps/<gitops-app-name>/overlays/<target-env>`
* `gitops-overlay-folder`
  * If this is not provided and `gitops-app-name` is provided, the value that will be used is: `apps/<gitops-app-name>/overlays`
  * When `target-env` contains multiple environments, file `<gitops-overlay-folder>/<env>/kustomize.yaml` will be edited.
  * When only one environment name is provided,
    if `<gitops-overlay-folder>/<env>` exist, `<gitops-overlay-folder>/<env>/kustomize.yaml` will be edited,
    otherwise file `<gitops-overlay-folder>/kustomize.yaml` will be edited.
* `gitops-repo-deployment-key`
    * The ssh key to clone and update the gitops repository.
    * Mandatory when deploy=yes, but mutual exclusive with the pair `gitops-repo-app-id` `gitops-repo-app-private-key`
* `gitops-repo-app-id` `gitops-repo-app-private-key`
    * The github AppID and its private key for obtaining a token, which is used to clone and update gitops repository.
    * Mandatory when deploy=yes, but mutual exclusive with `gitops-repo-deployment-key`.
    * If `gitops-repo-app-private-key` is specified but `gitops-repo-app-id` is not specified, 
      default to github action variable `GH_ACTION_APPID`
* `gitops-repo`
  * For example ecap-tech/eclipse-gitops.
  * If not provided, the github action variable `GITOPS_REPO` will be used if defined.
  * If GHA variable `GITOPS_REPO` is not defined either,
    repo `ecap-tech/eks-prod-001-manifests` will be used if the `target-env` is either `prod` or `stg`,
    otherwise, default to repo `ecap-tech/eks-nonprod-001-manifests`
* `gitops-branch`
  * If not provided, the github action variable `GITOPS_BRANCH` will be looked up, if not found, use value `main`

## Github vars context
* `vars`
  * Always pass the value to it as `${{ toJson(vars) }}`. This is the github action context containing effective 
    variables applied to the deployment environment
    * The following variable will always be looked up in this context:
      * `AZURE_ACR_CLIENT_ID`
      * `AZURE_SUBSCRIPTION_ID`
      * `AZURE_TENANT_ID`
      * `GH_ACTION_APPID`
