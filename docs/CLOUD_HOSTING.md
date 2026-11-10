# Cloud app hosting

This is a deployment variant of the existing headless Docker image. It needs one always-running container, one persistent writable volume, an HTTPS/WebSocket ingress, and your own licensed `Nighty.exe`. Never commit the executable or credentials to Git.

## Free hosting reality

Checked November 10, 2026:

| Provider | Free-plan result for Nighty |
| --- | --- |
| [Northflank Sandbox](https://northflank.com/pricing) | **Best candidate.** Advertises always-on services, Docker builds, and volumes within its free Sandbox allowance. Whether Nighty fits its CPU/RAM must be tested. |
| [Oracle Cloud Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) | Can run the existing Docker Compose setup on an Always Free VM, but requires administering Linux. Arm instances need Box64. Capacity is not guaranteed. |
| [Railway Free](https://docs.railway.com/pricing/free-trial) | $1/month after the trial. Useful to experiment, but unlikely to fund a 24/7 Wine container. |
| [Render Free](https://render.com/docs/free) | Sleeps after 15 idle minutes and cannot attach a persistent disk. Not suitable. |
| [Koyeb Free](https://www.koyeb.com/docs/reference/instances) | Scales to zero, cannot attach a volume, and offers only 512 MB RAM / 0.1 vCPU. Not suitable. |
| Vercel, Netlify, GitHub Actions | Functions/jobs have time limits and are not persistent container hosts. They can build or deploy this project but cannot run Nighty continuously. |

Synthetic keep-alive pings do not solve data loss or resource limits.

## Northflank Sandbox setup

1. Fork this repository to your Git account. Do not add `Nighty.exe`, `.env`, tokens, or a license key.
2. Create a Northflank Sandbox project and a **combined service** from your fork. Choose the root `Dockerfile` as build method. Use **one** instance and the largest CPU/RAM plan within the free allowance.
3. Add a **Single Read/Write** volume mounted at **`/data`**. The image specifies `USER nighty:nighty` for [volume permissions](https://northflank.com/docs/v1/application/databases-and-persistence/add-a-volume).
4. Set the service command to **`bash /app/scripts/cloud-entrypoint.sh`**. Expose container port **`8088`** as public **HTTP(S)/1.1**. Northflank supplies HTTPS and supports WebSockets. If you set `PORT`, set it to `8088`. [Port setup](https://northflank.com/docs/v1/application/network/configure-ports).
5. Add these **runtime** variables in the service Environment section:

   - `WEBUI_USERNAME`: a username you choose
   - `WEBUI_PASSWORD`: a unique password of at least 8 characters
   - `NIGHTY_EXE_URL`: a **private HTTPS download URL** for your licensed executable
   - `NIGHTY_EXE_SHA256`: its SHA-256 digest (64 hex characters)

   These are runtime secrets, not build arguments. A signed, expiring object-storage URL works: the executable downloads once to `/data/Nighty.exe`; later starts use the copy on the volume. Keep the URL valid through the first successful download. Alternatively, securely transfer the file to `/data/Nighty.exe` on the running service and omit both URL variables. Northflank [supports transferring files to a mounted volume](https://northflank.com/docs/v1/application/databases-and-persistence/add-a-volume).

6. Deploy and open the HTTPS URL. Complete the existing Nighty setup wizard with your own license and account credentials. First boot may take several minutes while it prepares Wine and the stub. Watch the service logs if it fails.

Get the SHA-256 on Windows with `Get-FileHash .\Nighty.exe -Algorithm SHA256`, or on Linux with `sha256sum Nighty.exe`.

The bridge's `/healthz` endpoint checks that the bridge is running. `/ready` is stricter and reports `ready: true` only when the native Nighty panel is up. For a platform health check during onboarding, use `/healthz` so it does not restart the wizard before setup is done.

## Other persistent-container hosts

Use the same Dockerfile and cloud start command on a host that keeps a container running and mounts a writable volume at `/data`:

- Set `WEBUI_USERNAME`, `WEBUI_PASSWORD`, and either an existing `/data/Nighty.exe` or `NIGHTY_EXE_URL` plus `NIGHTY_EXE_SHA256`.
- Route its HTTPS/WebSocket endpoint to `BRIDGE_PORT` (default `8088`). If the host injects `PORT`, the cloud command uses it unless `BRIDGE_PORT` is set.
- Use one instance against the volume. Nighty and its Wine prefix are single-instance state.
- Preserve `/data` across builds and restarts. It stores the executable, repacked stub, Wine prefix, license, tokens, extensions, and logs.

Regular `docker-compose.yml` remains the local/server path. The cloud command adds volume placement, port selection, and first-run acquisition of the executable before entering the existing Docker startup path.

## Security and limits

- The public URL leads to Nighty's login and first-run wizard. Use a strong Web UI password and the provider's HTTPS URL. Add a platform access rule if available.
- Treat `/data` and backups as sensitive. Never share raw diagnostic logs; they may contain tokens.
- No free plan guarantees uptime or enough resources to run a Windows application under Wine. An out-of-memory exit or plan change can make free deployment unusable.
- Nighty is proprietary and requires your own valid license. This wrapper is unofficial. Automated Discord user accounts may violate Discord's terms; review those rules before using it.
