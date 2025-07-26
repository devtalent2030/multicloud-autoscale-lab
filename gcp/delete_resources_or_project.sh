REGION=northamerica-northeast2
ZONE=northamerica-northeast2-a

# Managed Instance Group + autoscaler
gcloud compute instance-groups managed delete ogunrinu-assign1-mig --region $REGION -q

# Instance template
gcloud compute instance-templates delete ogunrinu-assign1-template -q

# Custom image
gcloud compute images delete ogunrinu-assign1-image -q

# Health check (if still present)
gcloud compute health-checks delete ogunrinu-assign1-hc -q

# Source VM (if you no longer need it)
gcloud compute instances delete ogunrinu-assign1-srcvm --zone $ZONE -q

# Optional firewall rule we added
gcloud compute firewall-rules delete default-allow-http -q




gcloud projects delete ogunrinu-assign1-project
# or via Console ▸ IAM & Admin ▸ Settings ▸ Shutdown
