# Modification Notice

This repository is a modified distribution derived from MCSManager.

Upstream project:

- MCSManager: https://github.com/MCSManager/MCSManager

License:

- Apache License 2.0, retained in [LICENSE](./LICENSE).
- Upstream copyright notices remain owned by their original holders.

Local changes made for this distribution:

- Rebranded user-facing panel names and assets to "稻荷社区".
- Replaced the frontend logo and favicon with local logo assets.
- Adjusted frontend navigation colors.
- Changed OAuth 2.0 userinfo extraction to support nested field paths, with the default user id path set to `data.user_id`.
- Removed selected user-facing links or pages from the frontend, including the node manual button, the settings about page, and the app market contribution template link.
- Added Linux production packaging and systemd installation scripts.

Date of local modification summary: 2026-06-20.
