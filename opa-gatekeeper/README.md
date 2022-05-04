# OPA Gatekeeper

## Usage

### kustomize
Install some or all of the templates alongside your own contraints [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/).

 Install everything with  `kubectl apply -k .`.

 ### oc

 Instead of using kustomize, you can directly apply the `template.yaml` and `constraint.yaml` provided in each directory

For example

```bash
cd opa-gatekeeper/httpsonly/
oc apply -f template.yaml
oc apply -f /test/constraint.yaml
```

## Testing
Verify that the policies are working as expected

For example

```bash
cd opa-gatekeeper/httpsonly/
oc apply -f /test/example_allowed.yaml
oc apply -f /test/example_disallowed.yaml

```
# Opa Gatekeeper/ArgoCD

##  Gatekeeper ArgoCD applicatie aanmaken  voor het sycnroniseren en toepassen van policies met [opa_argocd](/argocd/opa_argocd.yaml)

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gatekeeperpolicy
spec:
  destination:
    name: ''
    namespace: openshift-operators
    server: 'https://kubernetes.default.svc'
  source:
    path: opa-gatekeeper/deploy/used_policies
    repoURL: 'https://github.com/lanasak/Stage_FlowFactor'
    targetRevision: HEAD
    directory:
      recurse: true
  project: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: false

```

De gatekeeperpolicy applicatie in de UI:  
![gatekeeper](/images/gatekeeper.png)  

