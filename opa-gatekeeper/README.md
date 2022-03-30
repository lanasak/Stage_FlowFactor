# OPA Gatekeeper

## Usage

### kustomize
Install some or all of the templates alongside your own contraints [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)  install some or all of the templates alongside your own contraints.  

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
