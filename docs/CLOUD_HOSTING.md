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

Follow the [Northflank setup in the README](../README.md#northflank-step-by-step-setup). It walks through the Create new form shown in the Northflank app, then adds the volume from the service page. Use the `codex/cloud-hosting` branch of the aboveproof fork.

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
