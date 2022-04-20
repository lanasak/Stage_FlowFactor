# Gatekeeper policies samen met Compliance Operator

Er is overlap tussen een paar Gatekeeper policies en het creëren van Compliance Operator.

#### Container limits
Container limits: Vereist dat containers geheugen- en CPU-limieten hebben ingesteld en beperkt limieten om binnen de gespecificeerde maximumwaarden te blijven.  
Probleem: Het verzoek van Pods die zijn gegenereerd door job-controller, is afgewezen door validation gatekeeper.

#### Replica limits
Replica : Draait meerdere instanties van een Pod en houdt het opgegeven aantal Pods constant.  Met Replicalimits constraint zou vereisen dat objecten met het veld 'spec.replicas' aantal replica's specificeren binnen gedefinieerde bereiken.  
Probleem: Het aanmaken van Deployment met minimaal 3 replicas is te veel voor het aanmaken van alle nodige Deployments van Compliance Operator.
Compliance Operator creëert Deployments met 1 replica. De objecten met het veld spec.replicas bij compliance-operator, ocp4-openshift-compliance-pp en rhcos4-openshift-compliance-pp deployment zijn gedefinieerd met 1 replica.  


Vb. Deployment compliance-operator.yaml
```
kind: Deployment
apiVersion: apps/v1
metadata:
  annotations:
    deployment.kubernetes.io/revision: '1'
  resourceVersion: '7304453'
  name: compliance-operator
  uid: 2eb92197-97e6-4d5c-8983-26b1fa7c068c
  creationTimestamp: '2022-03-23T07:50:44Z'
  generation: 25
  managedFields:
    - manager: olm
      operation: Update
      apiVersion: apps/v1
      time: '2022-04-04T12:05:53Z'
      fieldsType: FieldsV1
      fieldsV1:
        'f:metadata':
          'f:labels':
.
.
.

spec:
  replicas: 1
  selector:
    matchLabels:
      name: compliance-operator
  template:
    metadata:
      creationTimestamp: null
      labels:
        name: compliance-operator
      annotations:
        olm.skipRange: '>=0.1.17 <0.1.48'
        olm.targetNamespaces: openshift-compliance
        operatorframework.io/properties: >-
     .
     .
     .
``` 

Ook de replica van network-check-source en network-operator Deployment is gedefinieerd met 1.  

Vb. Deployment network-operator.yaml
``` 
kind: Deployment
apiVersion: apps/v1
metadata:
  annotations:
    deployment.kubernetes.io/revision: '1'
    include.release.openshift.io/ibm-cloud-managed: 'true'
  resourceVersion: '7108999'
  name: network-operator
  uid: 41ba9405-5457-4c9a-b231-eea2de7d7741
  creationTimestamp: '2022-03-22T14:18:04Z'
  generation: 1
  .
  .
  .
  spec:
  replicas: 1
  selector:
    matchLabels:
      name: network-operator
  .
  .
  .
``` 


#### Required annotations
Required annotations: Vereist dat bronnen gespecificeerde annotaties bevatten, met waarden die overeenkomen met de opgegeven reguliere expressies.  
Probleem: Het is niet handig om altijd de owner als annotations te eisen bij het aanmaken van Service, automatische operators zoals compliance operator. Compliance operator definieert geen owner annotation bij het aanmaken van Service.  

Vb. Service compliance-operator.yaml  
```
kind: Service
apiVersion: v1
metadata:
  name: compliance-operator
  namespace: openshift-marketplace
  uid: 4d0bc129-d8c2-446c-ab27-e05977fd11df
  resourceVersion: '20188'
  creationTimestamp: '2022-03-22T14:58:38Z'
  labels:
    olm.service-spec-hash: 6dbffd894
  ownerReferences:
    - apiVersion: operators.coreos.com/v1alpha1
      kind: CatalogSource
      name: compliance-operator
      uid: a31542a0-0375-47da-9167-0aa7f1d9a916
      controller: false
      blockOwnerDeletion: false
  managedFields:
    - manager: catalog
      operation: Update
      apiVersion: v1
      time: '2022-03-22T14:58:38Z'
      fieldsType: FieldsV1
      fieldsV1:
        'f:metadata':
          'f:labels':
            .: {}
            'f:olm.service-spec-hash': {}
          'f:ownerReferences':
            .: {}
            'k:{"uid":"a31542a0-0375-47da-9167-0aa7f1d9a916"}': {}
        'f:spec':
          'f:internalTrafficPolicy': {}
          'f:ports':
            .: {}
            'k:{"port":50051,"protocol":"TCP"}':
              .: {}
              'f:name': {}
              'f:port': {}
              'f:protocol': {}
              'f:targetPort': {}
          'f:selector': {}
          'f:sessionAffinity': {}
          'f:type': {}
spec:
  clusterIP: 172.21.153.139
  ipFamilies:
    - IPv4
  ports:
    - name: grpc
      protocol: TCP
      port: 50051
      targetPort: 50051
  internalTrafficPolicy: Cluster
  clusterIPs:
    - 172.21.153.139
  type: ClusterIP
  ipFamilyPolicy: SingleStack
  sessionAffinity: None
  selector:
    olm.catalogSource: compliance-operator
status:
  loadBalancer: {}
```
#### required labels
Het ook is niet handig om altijd de owner label te eisen bij het aanmaken van namespace, het automatische installeren van operators zoals compliance operator. Compliance Operator definieert geen owner bij het aanmaken van namespace.  

Vb. Namespace compliance-operator.yaml
``` 
kind: Namespace
apiVersion: v1
metadata:
  name: openshift-compliance
  uid: 98a7f252-f2e6-456e-906e-3179f41a5e01
  resourceVersion: '466702'
  creationTimestamp: '2022-03-22T14:58:54Z'
  labels:
    kubernetes.io/metadata.name: openshift-compliance
    olm.operatorgroup.uid/25aacbd9-1a27-45b3-ba58-330416031d03: ''
    olm.operatorgroup.uid/e395ebb7-8d9f-4fdf-b5d5-26d6163ac490: ''
    openshift.io/cluster-monitoring: 'true'

``` 
## Mogelijke oplossingen
1. Alle overlappende "namespaces, pods, deployments, services, .." aanpassen om ze overeen te komen met reeds gedefinieerde policies.
2. De bovenstaande policies niet gebruiken als er een automatische installatie van operators moet uitgevoerd worden.
