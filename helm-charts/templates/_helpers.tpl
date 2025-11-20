{{/*
Expand the name of the chart.
*/}}
{{- define "swimlane-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "swimlane-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "swimlane-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "swimlane-app.labels" -}}
helm.sh/chart: {{ include "swimlane-app.chart" . }}
{{ include "swimlane-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "swimlane-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "swimlane-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
App component labels
*/}}
{{- define "swimlane-app.app.labels" -}}
helm.sh/chart: {{ include "swimlane-app.chart" . }}
{{ include "swimlane-app.app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: app
{{- end }}

{{/*
App selector labels
*/}}
{{- define "swimlane-app.app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "swimlane-app.name" . }}-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MongoDB component labels
*/}}
{{- define "swimlane-app.mongodb.labels" -}}
helm.sh/chart: {{ include "swimlane-app.chart" . }}
{{ include "swimlane-app.mongodb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: mongodb
{{- end }}

{{/*
MongoDB selector labels
*/}}
{{- define "swimlane-app.mongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "swimlane-app.name" . }}-mongodb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MongoDB fullname
*/}}
{{- define "swimlane-app.mongodb.fullname" -}}
{{- printf "%s-mongodb" (include "swimlane-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
App fullname
*/}}
{{- define "swimlane-app.app.fullname" -}}
{{- printf "%s-app" (include "swimlane-app.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "swimlane-app.serviceAccountName" -}}
{{- if .Values.app.serviceAccount.create }}
{{- default (include "swimlane-app.app.fullname" .) .Values.app.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.app.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MongoDB service account name
*/}}
{{- define "swimlane-app.mongodb.serviceAccountName" -}}
{{- if .Values.mongodb.serviceAccount.create }}
{{- default (include "swimlane-app.mongodb.fullname" .) .Values.mongodb.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.mongodb.serviceAccount.name }}
{{- end }}
{{- end }}

