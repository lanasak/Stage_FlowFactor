# Compliance Operator GitOps/ArgoCD

##  Installatie van de Compliance Operator via ArgoCD met [install-compliance-operato](/argocd/install.yaml)

```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: install-compliance-operator
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-compliance
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      recurse: true
    path: compliance-operator/co-install
    repoURL: 'https://github.com/lanasak/Stage_FlowFactor'
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```
Dit implementeert de openshift-compliance namespace die standaard niet bestaat. Om ArgoCD deze te laten maken, moeten we de volgende regel toevoegen aan onze syncPolicy: ``` syncOptions:
CreateNamespace=true ``` Dit zal ervoor zorgen dat de namespace wordt aangemaakt.   
Path co-install is gespecificeerd en de [co-install](compliance-operator/co-install/)  directory maakt de installatie vrij eenvoudig:  
- CatalogSource, om de lijst van beschikbare operators op te bouwen die kunnen worden geïnstalleerd vanuit OperatorHub in de OpenShift webconsole.  
- OperatorGroup, die bepaalt waar onze Operator zal kijken, en dus werken.

![install](/images/install.png)  
We hebben nu de Compliance Operator up and running, Om dat vanuit de CLI te controleer : 
```
$ oc get pods -n openshift-compliance
NAME                                              READY   STATUS    RESTARTS   AGE
compliance-operator-5cb9d9bc8b-frvgs              1/1     Running   0          68m
ocp4-openshift-compliance-pp-77849b4ff4-jw49d     1/1     Running   0          118m
rhcos4-openshift-compliance-pp-77c6d7f7fd-mbk6j   1/1     Running   0          138m
```
We kunnen ook zien dat de default ProfileBundles geldig zijn en klaar om gebruikt te worden:
```
$ oc get profilebundles -n openshift-compliance
NAME     CONTENTIMAGE                           CONTENTFILE         STATUS
ocp4     quay.io/complianceascode/ocp4:latest   ssg-ocp4-ds.xml     VALID
rhcos4   quay.io/complianceascode/ocp4:latest   ssg-rhcos4-ds.xml   VALID
```

## ArgoCD applicatie voor het scannen
We willen er nu voor zorgen dat de nodes op de juiste manier gescand worden.  

Hiervoor hebben we een ScanSettingsBinding nodig, deze bindt een profiel met scan-instellingen om scans te laten uitvoeren.  
Alvorens dit te doen, moet je weten dat ArgoCD geen rechten heeft om dit soort bronnen te bekijken of te beheren. Dus, als een extra stap, moeten we ze toevoegen [clusterrole](compliance-operator/clusterrole.yaml), [clusterrole_binding](compliance-operator/clusterrole_binding.yaml).  
ArgoCD applicatie aanmaken met [cis-scan](/argocd/scan/scan.yaml)
```
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSettingBinding
metadata:
  name: cis-scan
profiles:
- apiGroup: compliance.openshift.io/v1alpha1
  kind: Profile
  name: ocp4-cis
settingsRef:
  apiGroup: compliance.openshift.io/v1alpha1
  kind: ScanSetting
  name: default
```
ArgoCD applicatie annmaken voor het scannen [cis-scan](/argocd/scan/scan.yaml)
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cis-scan
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-compliance
    server: https://kubernetes.default.svc
  project: default
  source:
    directory:
      recurse: true
    path: compliance-operator/scan
    repoURL: https://github.com/lanasak/Stage_FlowFactor
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
De cis-scan applicatie in de UI:  
![cis-scan](/images/scan.png)  

En als de scan klaar is, zul je zien dat het doorgezet is
```
oc get compliancesuites -n openshift-compliance
NAME            PHASE   RESULT
cis-scan        DONE    NON-COMPLIANT
```
## ArgoCD applicatie voor het scannen en toepassen
Hier gaan we de gevonden remediatons automatisch toepassen.  
De ScanSettingBinding [cis-scan](compliance-operator/scan/scan.yaml) die we eerder gebruikten, bond het CIS profiel aan de `default` ScanSetting. Deze standaard opties staan alleen toe om dagelijkse scans te doen.  
Met dit type object kunnen we de operator ook vertellen dat we automatisch alle remediaties willen toepassen die de operator aanbeveelt [scan-and-apply](compliance-operator/scan-and-apply/scan.yaml) .
```
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSettingBinding
metadata:
  name: moderate-scan
profiles:
- apiGroup: compliance.openshift.io/v1alpha1
  kind: Profile
  name: rhcos4-moderate
settingsRef:
  apiGroup: compliance.openshift.io/v1alpha1
  kind: ScanSetting
  name: default-auto-apply
``` 
ArgoCD applicatie annmaken voor het scannen en toepassen ![scan-and-apply](/argocd/scan-and-apply.yaml)
```
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSettingBinding
metadata:
  name: moderate-scan
profiles:
- apiGroup: compliance.openshift.io/v1alpha1
  kind: Profile
  name: rhcos4-moderate
settingsRef:
  apiGroup: compliance.openshift.io/v1alpha1
  kind: ScanSetting
  name: default-auto-apply

```
De scan-and-apply applicatie in de UI:  
![scan-and-apply](/images/scan-and-apply.png)  

Als we de remedies controleren, zien we dat de remedies die door het moderate profiel zijn gegenereerd, zijn toegepast:
```
oc get complianceremediations -n openshift-compliance
NAME                                                    STATE
ocp4-cis-api-server-audit-log-maxsize                   NotApplied
ocp4-cis-audit-profile-set                              NotApplied
ocp4-moderate-api-server-audit-log-maxsize              Applied
ocp4-moderate-audit-error-alert-exists                  Applied
ocp4-moderate-audit-profile-set                         Applied
ocp4-moderate-oauth-or-oauthclient-inactivity-timeout   Applied
ocp4-moderate-oauth-or-oauthclient-token-maxage         Applied
```
