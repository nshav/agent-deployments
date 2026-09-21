{{/*
Expand the name of the chart.
*/}}
{{- define "test-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent.labels" -}}
app: {{ .Release.Name }}
version: {{ .Chart.AppVersion }}
{{- end }}

{{/*
Generate namespace name
*/}}
{{- define "agent.namespaceName" -}}
{{- if (.Values.namespaceCreation | default dict).name -}}
{{- .Values.namespaceCreation.name -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end }}

