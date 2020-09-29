# SPDX-FileCopyrightText: 2020 edef <edef@edef.eu>
# SPDX-License-Identifier: MIT
{
  services.prometheus.scrapeConfigs = [
    {
      job_name = "node";
      scrape_interval = "10s";
      static_configs = [
        {
          targets = [
            "localhost:9100"
          ];
          labels = {
            alias = "mon.nixcon.net";
          };
        }
      ];
    }
    {
      job_name = "prosody_muc";
      scrape_interval = "10s";
      metrics_path = "/stats";
      static_configs = [
        {
          targets = [
            "auth.jitsi.nixcon.net:5280"
          ];
          labels = {
            # TODO(edef): actually label this sanely
            alias = "jitsi.nixcon.net";
          };
        }
      ];
    }
  ];
}
