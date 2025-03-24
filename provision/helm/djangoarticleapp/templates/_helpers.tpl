{{/*
Return the chart name or override if provided.
*/}}
{{- define "djangoarticleapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the full name with the release name.
*/}}
{{- define "djangoarticleapp.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "djangoarticleapp.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
    