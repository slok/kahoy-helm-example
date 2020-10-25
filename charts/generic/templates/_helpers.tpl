{{- define "common-labels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: kahoy
team: {{ required "team is required" .Values.team }}
env: {{ required "environmentType is required" .Values.environmentType }}
{{- end }}