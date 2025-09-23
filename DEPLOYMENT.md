# CLAP Deployment Guide

## Automatisches CI/CD Deployment mit GitHub Actions

### Übersicht

Dieses Projekt verwendet GitHub Actions für automatisches Build und Deployment:
- Bei jedem Push zu `master` Branch werden automatisch Docker Images gebaut
- Images werden zu GitHub Container Registry (ghcr.io) gepusht
- Production Server kann die neuesten Images einfach pullen und deployen

### Setup

#### 1. GitHub Repository Setup

Das Repository muss öffentlich sein oder GitHub Packages aktiviert haben.

Die GitHub Actions Workflow-Datei ist bereits konfiguriert in `.github/workflows/docker-build-push.yml`

#### 2. Lokale Entwicklung

**Backend:**
```bash
cd clap-backend
# Lokale .env Datei wird NICHT zu Git committed (bereits in .gitignore)
mvn spring-boot:run
```

**Frontend:**
```bash
cd clap-frontend
# Lokale .env Datei wird NICHT zu Git committed (bereits in .gitignore)
npm start
```

#### 3. Production Server Setup

**Erstmaliges Setup:**

1. Repository klonen auf Production Server:
```bash
cd /opt
git clone https://github.com/DEIN-USERNAME/clap.git
cd clap
```

2. `.env` Datei auf dem Server erstellen (wird NICHT aus Git geladen):
```bash
cp .env.example .env
nano .env  # Produktive Werte eintragen
```

3. `GITHUB_REPOSITORY` Variable in `.env` setzen:
```bash
echo "GITHUB_REPOSITORY=DEIN-USERNAME/clap" >> .env
```

4. Erstmalig starten:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

#### 4. Updates Deployen

**Automatisch nach Git Push:**

Nach jedem Push zu `master`:
1. GitHub Actions baut automatisch neue Docker Images
2. Images werden zu ghcr.io gepusht
3. Auf dem Production Server einfach ausführen:

```bash
cd /opt/clap
./update-production.sh
```

**Oder manuell:**

```bash
cd /opt/clap
git pull  # Optional: für docker-compose.yml Updates
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

### Wichtige Hinweise

**Sicherheit:**
- ✅ `.env` Dateien werden NICHT committed (in .gitignore)
- ✅ Produktive Secrets bleiben auf dem Server
- ✅ Lokale Entwicklungs-.env wird nicht zu Git gepusht

**Docker Images:**
- Images sind verfügbar unter: `ghcr.io/DEIN-USERNAME/clap/clap-backend:latest`
- Images sind verfügbar unter: `ghcr.io/DEIN-USERNAME/clap/clap-frontend:latest`

**Environment Variablen:**
- Lokale Entwicklung: `.env` in `clap-backend/` und `clap-frontend/`
- Production: `.env` in `/opt/clap/` (für docker-compose)

### 5. Automatisches Deployment (Optional)

Du hast **zwei Optionen** für automatisches Deployment:

#### Option A: Webhook (Empfohlen - sofortiges Update)

GitHub triggert automatisch ein Update nach jedem Push:

1. Auf dem Production Server:
```bash
cd /opt/clap
chmod +x setup-webhook-server.sh
./setup-webhook-server.sh
```

2. Webhook Secret setzen:
```bash
# Generiere ein sicheres Secret
WEBHOOK_SECRET=$(openssl rand -hex 32)
echo $WEBHOOK_SECRET

# Trage es in /etc/webhook/hooks.json ein
nano /etc/webhook/hooks.json  # Replace WEBHOOK_SECRET_HERE
systemctl restart clap-webhook
```

3. GitHub Webhook einrichten:
   - Gehe zu: https://github.com/KruemmelS/clap/settings/hooks
   - "Add webhook"
   - Payload URL: `http://192.168.50.224:9000/hooks/clap-deploy`
   - Content type: `application/json`
   - Secret: (dein generiertes Secret)
   - Events: "Just the push event"

#### Option B: Cron Job (Einfacher - alle 5 Minuten)

Automatische Prüfung auf Updates alle 5 Minuten:

```bash
cd /opt/clap
chmod +x setup-cron-update.sh
./setup-cron-update.sh
```

Logs ansehen:
```bash
tail -f /var/log/clap-auto-update.log
```

### Troubleshooting

**Image Pull Fehler:**
Falls private Repository, zuerst login:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

**Service Status prüfen:**
```bash
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f clap-backend
```

**Kompletter Neustart:**
```bash
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```