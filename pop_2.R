# 1. Activating repositories ----

setRepositories()

# 2. Activating packages -----
libs <- c("arcgis", 
          "tidyverse", 
          "sf", 
          "terra", 
          "classInt", 
          "rayshader",
          "elevatr",
          "dots",
          "geodata")


installed_libs <- libs %in%  rownames(
  installed.packages()
)


if(any(installed_libs==FALSE)){
  install.packages(
    libs[!installed_libs],
    dependencies = TRUE
  )
}


invisible(lapply(
  libs, library, 
  character.only = TRUE
))


# 3. Population Data -----

url1 <- "https://services1.arcgis.com/ZGrptGlLV2IILABw/arcgis/rest/services/Pop_Admin1/FeatureServer/0"

data <- arcgislayers::arc_open(
  url1
)

admin1_population <- arcgislayers::arc_select(
  data,
  fields = c(
    "HASC_1", "ISO2", "Population"
  ),
  where = "ISO2 = 'PK'"
) |>
  sf::st_drop_geometry()


# 4. Sub-National Boundries -----


# Geodata server is down for maintenance at 17/12/2024 
# Here alternates are available to download and read shape files 

country_admin1_sf <- geodata::gadm(
  country = "PAK",
  level = 1,
  path = getwd()
) |>
  sf::st_as_sf() |>
  sf::st_cast("MULTIPOLYGON")

# Alternate ways to get sub-national boundries #


