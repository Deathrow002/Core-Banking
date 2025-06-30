# VS Code YAML Schema Configuration for Custom Resources
# This file helps VS Code understand Prometheus Operator CRDs

# Add this to your .vscode/settings.json:
# "yaml.schemas": {
#   "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/jsonnet/prometheus-operator/servicemonitor-crd.json": [
#     "k8s/prometheus-servicemonitors.yml"
#   ]
# }

# Alternatively, you can define the schema inline:
{
  "yaml.schemas": {
    "kubernetes": [
      "k8s/*.yml",
      "k8s/*.yaml"
    ],
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml": [
      "k8s/prometheus-servicemonitors.yml"
    ]
  }
}
