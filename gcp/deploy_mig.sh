#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  deploy_mig.sh  –  deploy a 2‑node auto‑scaling web tier on GCP
#  Author: Talent Nyota
#
#  Steps:
#    0) Prerequisite: you already have ONE VM running your website, then stop it.
#    1) Create custom image from that VM’s boot disk.
#    2) Build an instance template from the image.
#    3) Create a regional Managed Instance Group (MIG) with 2 replicas.
#    4) Attach autoscaling (min 2, max 4, 50 % CPU).
#
#  ---- Edit ONLY the block marked “CONFIGURABLE VARIABLES” for a new project. ----
# ---------------------------------------------------------------------------

set -e  # exit on first error

# ---------- CONFIGURABLE VARIABLES ----------
PROJECT_ID=$(gcloud config get-value project)          # change project via gcloud if needed
REGION=northamerica-northeast2                         # ✏️ target region
ZONE=northamerica-northeast2-a                         # ✏️ zone where source VM resides

SOURCE_DISK=ogunrinu-assign1-srcvm                     # ✏️ boot disk of your stopped VM
IMAGE_NAME=ogunrinu-assign1-image                      # ✏️ custom image name
IMAGE_FAMILY=ogunrinu-family                           # (optional) image family tag

TEMPLATE=ogunrinu-assign1-template                     # ✏️ instance template name
MIG=ogunrinu-assign1-mig                               # ✏️ managed instance group name
FWRULE=default-allow-http                              # firewall rule to open port 80
# --------------------------------------------

echo "Using project:   $PROJECT_ID"
echo "Creating image:  $IMAGE_NAME  from disk: $SOURCE_DISK"
echo "Region / zone:   $REGION / $ZONE"
echo "Template name:   $TEMPLATE"
echo "MIG name:        $MIG"
read -rp "Press ENTER to continue or Ctrl‑C to abort…"

# 1) Create custom image
gcloud compute images create "$IMAGE_NAME" \
  --source-disk="$SOURCE_DISK" \
  --source-disk-zone="$ZONE" \
  --family="$IMAGE_FAMILY" \
  --guest-os-features=VIRTIO_SCSI_MULTIQUEUE \
  --quiet

# 2) Build instance template
gcloud compute instance-templates create "$TEMPLATE" \
  --machine-type=e2-micro \                               # ✏️ size
  --image="$IMAGE_NAME" \
  --image-project="$PROJECT_ID" \
  --tags=http-server \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --quiet

# 3) Create firewall rule (runs once per project; ignore error if exists)
gcloud compute firewall-rules create "$FWRULE" \
  --allow tcp:80 --direction=INGRESS --target-tags=http-server \
  --description="Allow HTTP traffic to web instances" || true

# 4) Create Managed Instance Group
gcloud compute instance-groups managed create "$MIG" \
  --template="$TEMPLATE" \
  --region="$REGION" \
  --size=2 \
  --base-instance-name=ogunrinu \
  --quiet

# 5) Attach autoscaling policy
gcloud compute instance-groups managed set-autoscaling "$MIG" \
  --region="$REGION" \
  --min-num-replicas=2 \
  --max-num-replicas=4 \
  --target-cpu-utilization=0.50 \
  --cool-down-period=90 \
  --quiet

echo -e "\n✅  Deployment finished. Current instances:"
gcloud compute instance-groups managed list-instances "$MIG" \
  --region="$REGION" \
  --format="table(name,status,zone)"
