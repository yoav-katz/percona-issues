{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified app name based on the clusterName value.
*/}}
{{- define "pg-cluster.fullname" -}}
{{- default .Release.Name .Values.clusterName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels to append to your custom resources
*/}}
{{- define "pg-cluster.labels" -}}
app.kubernetes.io/name: {{ include "pg-cluster.fullname" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Calculate the target zone. Uses forceZone if provided, otherwise picks a random AZ.
*/}}
{{- define "pg-cluster.randomZone" -}}
{{- if .Values.forceZone -}}
{{- .Values.forceZone -}}
{{- else -}}
{{- $zones := list "az-a" "az-b" "az-c" -}}
{{- index $zones (randInt 0 3) -}}
{{- end -}}
{{- end -}}
