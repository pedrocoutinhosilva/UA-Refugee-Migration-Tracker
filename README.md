# UA-Refugee-Migration-Tracker

A R/Shiny dashboard to track Ukrainian Refugees movement across the border and neighboring countries.

It feeds of existing live data sources that are updated multiple times a day to keep data as up to date as possible.

Live version: https://sparktuga.shinyapps.io/shinyukraini/

# Installation

Clone the repository and make sure you have all required libraries. This project leverages `renv` for dependency management.

You can then run the app using `src/app.R`

Live border queues need a free [Nakordoni API key](https://nakordoni.eu/en/developers). Put it in `src/.Renviron` (ignored by git):

```
NAKORDONI_API_KEY=NKD-DEV-XXXX-XXXX-XXXX
```

Without a key the app still runs; border points show as "Not available". Queue data is cached for 2 hours to stay within the free tier's daily quota.

## Deploying (Posit Connect Cloud)

Publish from GitHub with primary file `src/app/app.R` and add `NAKORDONI_API_KEY` as a secret variable. Connect Cloud installs packages from `src/app/manifest.json`; after changing packages, regenerate it from `src/app` with `rsconnect::writeManifest(appPrimaryDoc = "app.R")`. `imola` and `shiny.pwa` are no longer on CRAN, so install them from GitHub (`pedrocoutinhosilva/imola`, `pedrocoutinhosilva/shiny.pwa`) before regenerating.

Every source is cached under `src/app/data/`. If a source is down or returns unusable data, the last good copy is used instead.

# Links

Data sources:
- [Eurostat - Beneficiaries of temporary protection](https://ec.europa.eu/eurostat/databrowser/view/migr_asytpsm/default/table) (monthly, EU neighbours)
- [UNHCR Refugee Data Finder](https://www.unhcr.org/refugee-statistics/) (yearly, Moldova, Belarus, Russia)
- [Border queues - Data by nakordoni.eu](https://nakordoni.eu)
- [Territorial control - DeepStateMap](https://deepstatemap.live)
