# Installatie en demo van Red Hat Service Mesh op OpenShift

## Introductie - OpenShift Service Mesh demo 
- OpenShift Service Mesh provisioneren met gebruik van Kubernetes operators
- configureer het om het voorbeeldproject Bookinfo te gebruiken - te vinden op de upstream Istio site
- demonstreer de verschillende mogelijkheden van OpenShift Service Mesh op het gebied van microservice management en visualisatie van het verkeer

## Instructies
We moeten 4 Operators installeren: 
- Elasticsearch
- Red Hat OpenShift gedistribueerd tracing platform
- Kiali - voor Service Mesh topologie visualisatie
- Red Hat OpenShift Service Mesh Operator   
Na de installatie van de vorige operator moeten we een Service Mesh maken van de Service Mesh operator.  
We maken een project (namespace) met de naam *istio-system* om de Service Mesh applicatie te houden. Dan maken we een nieuwe *Istio Service Mesh Control Plane* in namespace *istio-system*

```
kind: ServiceMeshControlPlane
apiVersion: maistra.io/v2
metadata:
  name: basic
  namespace: openshift-gitops
spec:
  version: v2.1
  tracing:
    type: Jaeger
    sampling: 10000
  policy:
    type: Istiod
  telemetry:
    type: Istiod
  addons:
    jaeger:
      install:
        storage:
          type: Memory
    prometheus:
      enabled: true
    kiali:
      enabled: true
    grafana:
      enabled: true

```

Nu zijn we klaar om Service Mesh controle toe te passen op een microservices Applicatie. We zullen gebruik maken van de Sample BookInfo applicatie - beschikbaar op de upstream Istio website.

Hier is een diagram van de applicatie:
![](/images/istio.png) 
Het is een zeer eenvoudige applicatie - een webpagina met de naam productpagina.  
Aan de linkerkant van het scherm zal het resultaat van de detailpagina worden weergegeven.  
Het meest interessant voor ons zijn de 3 reviews microservices - waarvan de resultaten aan de rechterkant van de webpagina zullen verschijnen.  
- wanneer v1 van reviews wordt aangeroepen - ratings wordt niet aangeroepen en er worden GEEN sterren getoond
- wanneer v2 van reviews wordt aangeroepen - ratings worden aangeroepen en ZWARTE sterren worden getoond
- wanneer v3 van beoordelingen wordt opgeroepen - beoordelingen worden opgeroepen en RODE sterren worden getoond  

Op dit punt, moeten we 3 dingen doen:

1. De eerste stap is het maken van een namespace voor de bookinfo applicatie - noem het *bookinfo*. Dit kan dit gedaan worden via de GUI of de command line - laten we het op de command line doen:

```
oc new-project bookinfo
```

2. De volgende stap is het aanmaken van een *Service Mesh Member Roll* op hetzelfde scherm waar we een nieuw *Istio Service Mesh Control Plane* over hebben aangemaakt - dit dicteert in wezen op welke namespaces we Service Mesh controle zullen toepassen. In ons geval *bookinfo*.  

3. Tenslotte installeer ik bookinfo microservices applicatie die Service Mesh Member Roll op uit is om controle op toe te passen. Ik doe dat door enkele yaml toe te passen die de Bookinfo Microservices applicatie installeert. Zodra deze is aangemaakt, zal de Service Mesh Member Roll er Service Mesh controle op toepassen.

```
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.1/samples/bookinfo/platform/kube/bookinfo.yaml
```

Vervolgens een Istio gateway - die de poort en het protocol op de ingress point van de mesh vertegenwoordigt (in ons geval HTTP en poort 80):
```
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.1/samples/bookinfo/networking/bookinfo-gateway.yaml
```

Vervolgens de Istio Bestemmingsregels:
```
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.1/samples/bookinfo/networking/destination-rule-all.yaml
```
Nu, is de Gateway URL: 
```
set GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
echo $GATEWAY_URL
```
Voor het bekijken van de Product Pagina onder Service Mesh controle voegen we het pad */productpage* toe aan de gateway URL.


Als we deze pagina een paar keer vernieuwen kunnen we zien dat hij door de Review Microservice versies loopt - met
 - geen sterren v1  
 ![](/images/bookinfo-v1.png)   
 
 - zwarte sterren v2
 ![](/images/bookinfo-v2.png.png)   
 
 - rode sterren v3  
 ![](/images/bookinfo.png) 

Via Kiali, werd de topologie gevisualiseerd
![](/images/kiali.png) 

Hier worden de versies van de services getest. Stel dat we versie 1 niet meer willen gebruiken en nog niet zeker zijn of we verder willen gaan met versie 2 of 3. Dus we sturen 50% naar beide, ongeacht wie er is ingelogd:
```
oc replace -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-reviews-v2-v3.yaml
```
Na herhaaldelijk verversen van de webpagina. We zien de helft van de resultaten met rode en de andere helft met zwarte sterren, zoals verwacht.   
Stel dat we tevreden zijn met versie 3 en we willen die uitrollen naar 100% van het verkeer:
```
oc replace -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/networking/virtual-service-reviews-v3.yaml
```
![](/images/bookinfo-v3.png) 

## Service Mesh Security:
-	Mutual Transport Layer Security (mTLS):  
Mutual Transport Layer Security is een protocol dat twee partijen in staat stelt elkaar te authenticeren. Het is de standaard authenticatiemethode in sommige protocollen (IKE, SSH) en optioneel in andere (TLS). Er kan gebruik gemaakt van mTLS zonder wijzigingen in de applicatie- of servicecode. De TLS wordt volledig afgehandeld door de service mesh infrastructuur en tussen de twee sidecar proxies.  
Het inschakelen van mTLS in uw mesh op control plane niveau beveiligt al het verkeer in de service mesh zonder herschrijven van de applicaties en workloads. Het beveiligen van namespaces in de mesh kan op data plane niveau in de ServiceMeshControlPlane resource. Om verbindingen voor verkeerscodering aan te passen, worden de namespaces geconfigureerd op applicatieniveau met PeerAuthentication en DestinationRule resources.  
 [PeerAuthentication Policy](Policy.yaml)

```
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: default
  namespace: bookinfo
spec:
  peers:
    - mtls: STRICT
```
 [DestinationRule](DestinationRule.yaml) 

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: default
  namespace: bookinfo
spec:
  host: "*.bookinfo.svc.cluster.local"
  trafficPolicy:
   tls:
    mode: ISTIO_MUTUAL
```

De encryptie valideren met Kiali  
![](/images/mtls.png)   
![](/images/mTLS-encryptie.png) 

- Role Based Access Control (RBAC) configureren:  
Role Based Access Control bepaalt of een gebruiker of service een bepaalde actie mag uitvoeren binnen een project. Er kan mesh-, namespace- en workloadbrede toegangscontrole gedefinieerd worden voor de workloads in de mesh.  
 Beperk de toegang tot diensten buiten een namespace  [access-namespace](access-namespace.yaml)   
 Er kunnen verzoeken geweigerd worden van elke bron die niet in de bookinfo namespace staat met het volgende AuthorizationPolicy resource
 ```
 apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin-deny
 namespace: bookinfo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: DENY
 rules:
 - from:
   - source:
       notNamespaces: ["bookinfo"]
 ```
 


 


