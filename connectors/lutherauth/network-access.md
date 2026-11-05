---
description: Limit which pods can reach LutherAuth in Kubernetes, and keep the fake IdP unreachable.
---

# Network Access

In Kubernetes, any pod can call any Service by default. Without a limit, any pod can try client secrets against the LutherAuth token endpoint. It can also reach the fake IdP if someone turns it on. In many deployments, third-party images such as MCP connectors run in the same cluster as LutherAuth. Use the controls on this page so that only the callers that need LutherAuth can reach it.

| Control | What it stops |
|---|---|
| [Route only `/v1/auth`](#route-only-v1auth) | Requests from outside the cluster to the fake IdP |
| [Ingress NetworkPolicy on the LutherAuth pods](#add-an-ingress-networkpolicy) | Requests from pods that you did not list |
| `pods/exec` permission on the LutherAuth namespace | Token minting by people who must not mint (see [Who can mint](service-tokens.md#who-can-mint)) |

---

## Route only /v1/auth

Route only the `/v1/auth` path prefix to LutherAuth in your ingress. The fake IdP path is `/test/fakeidp/token` by default (`jwt-endpoint-fake-idp-path`). A request from outside the cluster then cannot reach the fake IdP, even if it is on. Keep `jwt-endpoint-fake-idp-path` outside `/v1/auth`.

---

## Add an ingress NetworkPolicy

A NetworkPolicy has an effect only when the cluster's network plugin enforces it. A policy that is not enforced fails no request and shows no error. Make sure that your plugin enforces policies before you rely on one:

- Amazon EKS with the VPC CNI: set `enableNetworkPolicy` to `true` in the `vpc-cni` add-on configuration.
- Calico and Cilium: enforcement is on by default.

When one policy selects the LutherAuth pods, the cluster drops every connection that no policy allows. So list every caller:

- the path from your load balancer or ingress controller
- each service that reads the JWKS or calls LutherAuth inside the cluster
- your metrics scraper, if it scrapes LutherAuth

### Find your labels and port

The policy selects pods by label and allows a container port, not the Service port. Read both from your deployment:

```bash
kubectl get pods -n <lutherauth namespace> --show-labels
kubectl get deploy -n <lutherauth namespace> <lutherauth deployment> \
  -o jsonpath='{.spec.template.spec.containers[0].ports}'
```

LutherAuth listens on `listen-addr` (default `:8080`). The Luther Helm chart sets the pod label `app.kubernetes.io/name: lutherauth` and the listen port `7070`, behind a Service on port `80`. The examples below use the values of the Luther Helm chart.

### Example with an ingress controller

Use this form when an ingress controller pod (for example ingress-nginx) forwards the requests to LutherAuth.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: lutherauth-ingress
  namespace: <lutherauth namespace>
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: lutherauth
  policyTypes: [Ingress]
  ingress:
    - from:
        # The ingress controller.
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
        # Callers in the LutherAuth namespace.
        - podSelector:
            matchLabels:
              lutherauth-client: "true"
        # Callers in another namespace. Keep both selectors in one entry:
        # the pod must match the label AND be in that namespace.
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: <caller namespace>
          podSelector:
            matchLabels:
              lutherauth-client: "true"
      ports:
        - protocol: TCP
          port: 7070
```

### Load balancer in IP mode

An AWS Load Balancer Controller in IP mode (`alb.ingress.kubernetes.io/target-type: ip`) sends requests straight to the pod IPs. No ingress controller pod is in the path, so the policy must allow the load balancer's IP addresses with an `ipBlock`.

Do this only if no pods run in the load balancer's subnets. With the VPC CNI, pods take IPs from the node subnets. An `ipBlock` that covers a node subnet lets in every pod in that subnet, and the policy then protects nothing.

If the load balancer and the nodes share subnets, use one of these:

- Move the load balancer to subnets that hold no nodes, and allow those subnets with an `ipBlock`.
- Use security groups for pods. Allow only the load balancer's security group and the callers' security groups to reach the LutherAuth pods.

### Things to check

- Kubelet health probes come from the node. The VPC CNI, Calico and Cilium allow them by default. Make sure that the pods stay ready after you apply the policy.
- `kubectl exec` (for `mint-token`) goes through the Kubernetes API, not the pod network. The policy does not affect it.

---

## Test the policy

Run these tests after you apply the policy. Services that use lutherauth-sdk-go keep the JWKS in a cache for up to 10 minutes. Wait 10 minutes, or restart a caller, before you decide that a caller still works.

| Test | Expected result |
|---|---|
| Browser login through your public host | Works |
| A call to a service that checks tokens in the cluster, after a restart of that service | Works |
| The test command below, from a pod that is not listed | Times out |
| The same command run before the policy is applied | Returns the JWKS |

Run the test command in the LutherAuth namespace, so that the Service name resolves. Use the Service port (`80` in the Luther Helm chart), not the container port:

```bash
kubectl run -n <lutherauth namespace> -it --rm nettest --image=curlimages/curl -- \
  curl -sS -m 5 http://<lutherauth service>:80/v1/auth/.well-known/jwks.json
```

A test that returns the JWKS before the policy and times out after it shows that the policy is enforced. If the command fails with "Could not resolve host", the Service name or the namespace is wrong, and the test proves nothing.
